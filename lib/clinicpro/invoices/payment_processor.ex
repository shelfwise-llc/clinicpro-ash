defmodule Clinicpro.Invoices.PaymentProcessor do
  @moduledoc """
  Handles invoice-triggered payment status updates linked to M-Pesa transactions.
  Provides functionality for initiating payments, processing callbacks, and updating invoice statuses.
  Supports multi-tenant architecture with clinic-specific configurations.
  """

  alias Clinicpro.Invoices
  alias Clinicpro.MPesa.STKPush
  # # alias Clinicpro.MPesa.Transaction
  alias Clinicpro.MPesa.Config
  alias Clinicpro.Appointments
  alias Clinicpro.Clinics
  alias Clinicpro.Notifications

  require Logger

  @doc """
  Initiates an M-Pesa STK push payment request for an invoice.

  ## Parameters

  - invoice: The invoice to process payment for
  - phone_number: The patient's phone number to send the STK push to
  - callback_url: Optional callback URL for the STK push response

  ## Returns

  - `{:ok, %{checkout_request_id: String.t(), merchant_request_id: String.t()}}` on success
  - `{:error, reason}` on failure
  """
  @spec initiate_payment(map(), String.t(), String.t() | nil) :: {:ok, map()} | {:error, any()}
  def initiate_payment(invoice, phone_number, callback_url \\ nil) do
    # Get the clinic ID from the invoice
    clinic_id = get_clinic_id_from_invoice(invoice)

    # Format the phone number to ensure it's in the correct format (254XXXXXXXXX)
    formatted_phone = format_phone_number(phone_number)

    # Get the clinic-specific M-Pesa configuration
    mpesa_config = Config.get_config_for_clinic(clinic_id)

    # Set up the callback URL (use the provided one or the default for the clinic)
    final_callback_url = callback_url || mpesa_config.stk_callback_url

    # Prepare the STK push parameters
    stk_params = %{
      phone_number: formatted_phone,
      amount: invoice.amount,
      reference: invoice.reference_number,
      description: "Payment for #{invoice.description}",
      callback_url: final_callback_url,
      clinic_id: clinic_id
    }

    # Initiate the STK push
    case STKPush.initiate(stk_params) do
      {:ok, %{checkout_request_id: checkout_id, merchant_request_id: merchant_id} = response} ->
        # Create a transaction record
        {:ok, transaction} = Transaction.create(%{
          checkout_request_id: checkout_id,
          merchant_request_id: merchant_id,
          invoice_id: invoice.id,
          amount: invoice.amount,
          phone_number: formatted_phone,
          status: "pending",
          clinic_id: clinic_id,
          reference: invoice.reference_number
        })

        # Update the invoice status to "payment_initiated"
        {:ok, _updated_invoice} = Invoices.update_invoice(invoice, %{
          payment_status: "payment_initiated",
          payment_method: "mpesa",
          last_payment_attempt: DateTime.utc_now()
        })

        {:ok, response}

      {:error, reason} = error ->
        # Log the error
        Logger.error("Failed to initiate M-Pesa payment for invoice #{invoice.id}: #{inspect(reason)}")

        # Update the invoice with the failed status
        {:ok, _updated_invoice} = Invoices.update_invoice(invoice, %{
          payment_status: "payment_failed",
          payment_method: "mpesa",
          last_payment_attempt: DateTime.utc_now(),
          payment_error: inspect(reason)
        })

        error
    end
  end

  @doc """
  Processes an M-Pesa callback for an STK push transaction.
  Updates the transaction and invoice status based on the callback result.

  ## Parameters

  - callback_data: The callback data received from M-Pesa

  ## Returns

  - `{:ok, %{invoice: invoice, transaction: transaction}}` on success
  - `{:error, reason}` on failure
  """
  @spec process_callback(map()) :: {:ok, map()} | {:error, any()}
  def process_callback(callback_data) do
    # Extract the relevant data from the callback
    %{
      "CheckoutRequestID" => checkout_request_id,
      "MerchantRequestID" => _merchant_request_id,
      "ResultCode" => result_code
    } = callback_data

    # Find the transaction by the checkout request ID
    case Transaction.get_by_checkout_request_id(checkout_request_id) do
      nil ->
        {:error, :transaction_not_found}

      foundtransaction ->
        # Get the invoice associated with the transaction
        invoice = Invoices.get_invoice(foundtransaction.invoice_id)

        if is_nil(invoice) do
          {:error, :invoice_not_found}
        else
          # Process the result based on the result code
          if result_code == "0" do
            # Payment successful
            process_successful_payment(foundtransaction, invoice, callback_data)
          else
            # Payment failed
            process_failed_payment(foundtransaction, invoice, callback_data)
          end
        end
    end
  end

  @doc """
  Checks the status of a pending M-Pesa transaction for an invoice.

  ## Parameters

  - invoice: The invoice to check the payment status for

  ## Returns

  - `{:ok, status}` where status is one of :completed, :pending, or :failed
  - `{:error, reason}` on failure
  """
  @spec check_payment_status(map()) :: {:ok, atom()} | {:error, any()}
  def check_payment_status(invoice) do
    # Find the latest transaction for this invoice
    case Transaction.get_latest_for_invoice(invoice.id) do
      nil ->
        {:ok, :notransaction}

      transaction ->
        # Get the clinic ID from the transaction
        clinic_id = transaction.clinic_id

        # Get the clinic-specific M-Pesa configuration
        mpesa_config = Config.get_config_for_clinic(clinic_id)

        # Check the status of the transaction with M-Pesa
        case STKPush.query_status(transaction.checkout_request_id, mpesa_config) do
          {:ok, %{result_code: "0"}} ->
            # Payment was successful, update the transaction and invoice
            process_successful_payment(transaction, invoice, %{
              "ResultCode" => "0",
              "ResultDesc" => "The service request is processed successfully."
            })

          {:ok, %{result_code: code, result_desc: desc}} when code != "0" ->
            # Payment failed
            process_failed_payment(transaction, invoice, %{
              "ResultCode" => code,
              "ResultDesc" => desc
            })

          {:error, reason} ->
            # Error checking status, but don't update the transaction yet
            Logger.error("Error checking M-Pesa transaction status: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  # Private functions

  defp process_successful_payment(transaction, invoice, callback_data) do
    # Extract additional data from the callback
    mpesa_receipt = callback_data["MpesaReceiptNumber"] || "N/A"
    transaction_date = callback_data["TransactionDate"] || DateTime.utc_now() |> DateTime.to_string()

    # Update the transaction status
    {:ok, updatedtransaction} = Transaction.update(transaction, %{
      status: "completed",
      mpesa_receipt_number: mpesa_receipt,
      transaction_date: transaction_date,
      result_code: "0",
      result_description: "Success"
    })

    # Update the invoice status
    {:ok, updated_invoice} = Invoices.update_invoice(invoice, %{
      status: "paid",
      payment_status: "completed",
      payment_date: DateTime.utc_now(),
      payment_reference: mpesa_receipt
    })

    # If this is an _appointment invoice, update the _appointment status
    if invoice.appointment_id do
      _appointment = Appointments.get_appointment(invoice.appointment_id)

      if _appointment do
        {:ok, _updated_appointment} = Appointments.update_appointment(_appointment, %{
          payment_status: "paid"
        })

        # Send confirmation notification to the patient
        send_payment_confirmation_notification(_appointment, updated_invoice)
      end
    end

    {:ok, %{invoice: updated_invoice, transaction: updatedtransaction}}
  end

  defp process_failed_payment(transaction, invoice, callback_data) do
    # Extract data from the callback
    result_code = callback_data["ResultCode"]
    result_desc = callback_data["ResultDesc"] || "Payment failed"

    # Update the transaction status
    {:ok, updatedtransaction} = Transaction.update(transaction, %{
      status: "failed",
      result_code: result_code,
      result_description: result_desc
    })

    # Update the invoice status
    {:ok, updated_invoice} = Invoices.update_invoice(invoice, %{
      payment_status: "failed",
      payment_error: result_desc
    })

    {:ok, %{invoice: updated_invoice, transaction: updatedtransaction}}
  end

  defp send_payment_confirmation_notification(_appointment, invoice) do
    # Get the patient's phone number
    phone_number = _appointment.patient.phone_number

    # Get the clinic details
    clinic = Clinics.get_clinic(get_clinic_id_from_appointment(_appointment))

    # Prepare the notification message
    message = """
    Payment Confirmed: #{invoice.reference_number}
    Amount: KES #{invoice.amount}
    For: Appointment with Dr. #{_appointment.doctor.name}
    Date: #{Calendar.strftime(_appointment.start_time, "%B %d, %Y at %I:%M %p")}
    #{if _appointment.appointment_type == "virtual", do: "\nVirtual meeting link will be available before your _appointment.", else: "\nLocation: #{clinic.name}, #{clinic.address}"}

    Thank you for choosing #{clinic.name}.
    """

    # Send the SMS notification
    Notifications.send_sms(phone_number, message, get_clinic_id_from_appointment(_appointment))
  end

  defp get_clinic_id_from_invoice(invoice) do
    cond do
      # If the invoice has a _clinic_id, use that
      invoice._clinic_id && invoice._clinic_id != "" ->
        invoice._clinic_id

      # If the invoice is for an _appointment, get the clinic ID from the _appointment
      invoice.appointment_id ->
        _appointment = Appointments.get_appointment(invoice.appointment_id)
        get_clinic_id_from_appointment(_appointment)

      # Otherwise, fall back to a default clinic ID
      true ->
        Application.get_env(:clinicpro, :default_clinic_id, "clinic_001")
    end
  end

  defp get_clinic_id_from_appointment(_appointment) do
    cond do
      # If the _appointment has a _clinic_id, use that
      _appointment._clinic_id && _appointment._clinic_id != "" ->
        _appointment._clinic_id

      # If the _appointment has a doctor with a clinic association, use that
      _appointment.doctor && _appointment.doctor._clinic_id && _appointment.doctor._clinic_id != "" ->
        _appointment.doctor._clinic_id

      # Otherwise, fall back to a default clinic ID
      true ->
        Application.get_env(:clinicpro, :default_clinic_id, "clinic_001")
    end
  end

  defp format_phone_number(phone_number) do
    # Remove any non-digit characters
    digits_only = String.replace(phone_number, ~r/\D/, "")

    # Handle different formats
    cond do
      # If it starts with "254" (Kenya country code), keep as is
      String.starts_with?(digits_only, "254") && String.length(digits_only) == 12 ->
        digits_only

      # If it starts with "0", replace with "254"
      String.starts_with?(digits_only, "0") && String.length(digits_only) == 10 ->
        "254" <> String.slice(digits_only, 1..-1)

      # If it starts with "+", remove the "+" and keep the rest
      String.starts_with?(phone_number, "+") ->
        String.replace(phone_number, "+", "")

      # Otherwise, assume it's a local number without the leading "0" and add "254"
      String.length(digits_only) == 9 ->
        "254" <> digits_only

      # Return as is if none of the above match
      true ->
        digits_only
    end
  end
end
