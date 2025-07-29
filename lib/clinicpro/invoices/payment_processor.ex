defmodule Clinicpro.Invoices.PaymentProcessor do
  @moduledoc """
  Handles invoice-triggered payment status updates linked to Paystack transactions.
  Provides functionality for initiating payments, processing callbacks, and updating invoice statuses.
  Supports multi-tenant architecture with clinic-specific configurations.
  """

  alias Clinicpro.Invoices.Invoice
  alias Clinicpro.PaystackLegacy
  alias Clinicpro.PaystackLegacy.Transaction
  alias Clinicpro.PaystackLegacy.Config
  alias Clinicpro.Clinics
  alias Clinicpro.Notifications
  alias Clinicpro.Appointments.Appointment

  require Logger

  @doc """
  Initiates a Paystack payment request for an invoice.

  ## Parameters

  - invoice: The invoice to process payment for
  - email: The patient's email address for the payment
  - callback_url: Optional callback URL for the payment response

  ## Returns

  - `{:ok, %{reference: String.t(), authorization_url: String.t()}}` on success
  - `{:error, reason}` on failure
  """
  @spec initiate_payment(map(), String.t(), String.t() | nil) :: {:ok, map()} | {:error, any()}
  def initiate_payment(invoice, email, callback_url \\ nil) do
    # Get the clinic ID from the invoice
    clinic_id = get_clinic_id_from_invoice(invoice)

    # Get the clinic-specific Paystack configuration
    paystack_config = Config.get_config(clinic_id)

    # Set up the callback URL (use the provided one or the default for the clinic)
    final_callback_url = callback_url || paystack_config.callback_url

    # Prepare the payment parameters
    payment_params = %{
      email: email,
      # Convert to kobo/cents
      amount: Decimal.mult(invoice.amount, Decimal.new(100)) |> Decimal.to_integer(),
      reference: invoice.reference_number,
      metadata: %{
        invoice_id: invoice.id,
        clinic_id: clinic_id,
        description: "Payment for #{invoice.description}"
      },
      callback_url: final_callback_url
    }

    # Attempt to initiate the Paystack payment
    case Paystack.initiate_payment(payment_params) do
      {:ok, %{transaction: transaction, authorization_url: _url}} ->
        # Transaction record is already created by Paystack.initiate_payment
        _transaction = %{
          invoice_id: invoice.id,
          reference: transaction.reference,
          email: email,
          amount: invoice.amount,
          status: "pending",
          payment_method: "paystack",
          clinic_id: clinic_id,
          authorization_url: transaction.authorization_url
        }

        # Update the invoice status to "payment_initiated"
        {:ok, _updated_invoice} =
          Clinicpro.Invoices.update_invoice_status(invoice, %{
            payment_status: "payment_initiated",
            payment_method: "paystack",
            last_payment_attempt: DateTime.utc_now()
          })

        {:ok,
         %{reference: transaction.reference, authorization_url: transaction.authorization_url}}

      {:error, reason} = error ->
        # Log the error
        Logger.error(
          "Failed to initiate Paystack payment for invoice #{invoice.id}: #{inspect(reason)}"
        )

        # Update the invoice with the failed status
        {:ok, _updated_invoice} =
          Clinicpro.Invoices.update_invoice_status(invoice, %{
            payment_status: "payment_failed",
            payment_method: "paystack",
            last_payment_attempt: DateTime.utc_now(),
            payment_error: inspect(reason)
          })

        error
    end
  end

  @doc """
  Processes a Paystack callback for a transaction.
  Updates the transaction and invoice status based on the callback result.

  ## Parameters

  - callback_data: The callback data received from Paystack

  ## Returns

  - `{:ok, %{invoice: invoice, transaction: transaction}}` on success
  - `{:error, reason}` on failure
  """
  @spec process_callback(map()) :: {:ok, map()} | {:error, any()}
  def process_callback(callback_data) do
    with reference <- Map.get(callback_data, "reference"),
         {:ok, transaction} <- {:ok, Transaction.get_by_reference(reference, 1)},
         invoice_id <- transaction.invoice_id,
         invoice <- Clinicpro.AdminBypass.Invoice.get(invoice_id) do
      # Get the status from the callback data
      status = Map.get(callback_data, "status", "failed")

      # Update the transaction status
      {:ok, transaction} =
        Transaction.update(transaction, %{
          status: status,
          callback_data: callback_data
        })

      handle_callback_result(transaction, invoice, callback_data, status)
    end
  end

  defp handle_callback_result(_transaction, nil, _callback_data, _status) do
    {:error, :invoice_not_found}
  end

  defp handle_callback_result(transaction, invoice, callback_data, "success") do
    # Payment successful
    process_successful_payment(transaction, invoice, callback_data)
  end

  defp handle_callback_result(transaction, invoice, callback_data, _status) do
    # Payment failed
    process_failed_payment(transaction, invoice, callback_data)
  end

  @doc """
  Checks the status of a pending Paystack transaction for an invoice.

  ## Parameters

  - invoice: The invoice to check the payment status for

  ## Returns

  - `{:ok, status}` where status is one of :completed, :pending, or :failed
  - `{:error, reason}` on failure
  """
  @spec check_payment_status(map()) :: {:ok, atom()} | {:error, any()}
  def check_payment_status(invoice) do
    # Find the latest transaction for this invoice
    # Get transaction by invoice reference (using invoice.id as reference)
    case Transaction.get_by_reference(invoice.id, 1) do
      nil ->
        {:ok, :notransaction}

      transaction ->
        # Get the clinic ID from the transaction and verify payment
        verify_transaction_payment(transaction, invoice)
    end
  end

  # Helper function to verify payment status and process accordingly
  defp verify_transaction_payment(transaction, invoice) do
    # Get the clinic ID from the transaction
    clinic_id = transaction.clinic_id

    # Get the clinic-specific Paystack configuration
    _paystack_config = Config.get_config(clinic_id)

    # Query the transaction status from Paystack
    case Paystack.verify_payment(transaction.reference, clinic_id) do
      {:ok, %{status: "success"}} ->
        # Payment was successful, update the transaction and invoice
        process_successful_payment(transaction, invoice, %{
          "status" => "success",
          "message" => "Payment was successful"
        })

      {:ok, %{status: status, message: message}}
      when status in ["failed", "abandoned", "cancelled"] ->
        # Payment failed, update the transaction and invoice
        process_failed_payment(transaction, invoice, %{
          "status" => status,
          "message" => message
        })

      {:ok, %{status: "pending"}} ->
        # Payment is still pending
        {:ok, :pending}

      {:error, reason} ->
        # Error checking the status, log it but don't update the transaction yet
        Logger.error("Error checking Paystack transaction status: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp process_successful_payment(transaction, invoice, response) do
    # Update the transaction record
    {:ok, updated_transaction} =
      Transaction.update(transaction, %{
        status: "completed",
        paystack_reference: response["reference"],
        response_data: response
      })

    # Update the invoice status
    {:ok, updated_invoice} =
      Clinicpro.Invoices.update_invoice_status(invoice, %{
        status: "paid",
        payment_status: "completed",
        payment_date: DateTime.utc_now(),
        payment_reference: response["reference"]
      })

    # Update appointment if needed
    update_appointment_if_needed(invoice)

    {:ok, %{invoice: updated_invoice, transaction: updated_transaction}}
  end

  defp process_failed_payment(transaction, invoice, response) do
    # Update the transaction record
    {:ok, updated_transaction} =
      Transaction.update(transaction, %{
        status: "failed",
        response_data: response
      })

    # Update the invoice status
    {:ok, updated_invoice} =
      Clinicpro.Invoices.update_invoice_status(invoice, %{
        payment_status: "failed",
        payment_error: response["message"] || "Payment failed"
      })

    {:ok, %{invoice: updated_invoice, transaction: updated_transaction}}
  end

  defp send_payment_confirmation_notification(appointment, invoice) do
    # Get the patient's phone number
    phone_number = appointment.patient.phone_number

    # Get the clinic details
    clinic =
      Clinicpro.Clinics.get(Clinicpro.Clinics.Clinic, get_clinic_id_fromappointment(appointment))

    # Prepare the notification message
    message = """
    Payment Confirmed: #{invoice.reference_number}
    Amount: KES #{invoice.amount}
    For: Appointment with Dr. #{appointment.doctor.name}
    Date: #{Calendar.strftime(appointment.start_time, "%B %d, %Y at %I:%M %p")}
    #{if appointment.appointment_type == "virtual", do: "\nVirtual meeting link will be available before your appointment.", else: "\nLocation: #{clinic.name}, #{clinic.address}"}

    Thank you for choosing #{clinic.name}.
    """

    # Send the SMS notification
    Notifications.send_sms(phone_number, message, get_clinic_id_fromappointment(appointment))
  end

  defp get_clinic_id_from_invoice(invoice) do
    cond do
      # If the invoice has a clinic_id, use that
      invoice.clinic_id && invoice.clinic_id != "" ->
        invoice.clinic_id

      # If the invoice is for an appointment, get the clinic ID from the appointment
      invoice.appointment_id ->
        appointment = Clinicpro.Appointment.get(invoice.appointment_id)
        get_clinic_id_fromappointment(appointment)

      # Otherwise, fall back to a default clinic ID
      true ->
        Application.get_env(:clinicpro, :defaultclinic_id, "clinic_001")
    end
  end

  defp get_clinic_id_fromappointment(appointment) do
    cond do
      # If the appointment has a clinic_id, use that
      appointment.clinic_id && appointment.clinic_id != "" ->
        appointment.clinic_id

      # If the appointment has a doctor with a clinic association, use that
      appointment.doctor && appointment.doctor.clinic_id &&
          appointment.doctor.clinic_id != "" ->
        appointment.doctor.clinic_id

      # Otherwise, fall back to a default clinic ID
      true ->
        Application.get_env(:clinicpro, :defaultclinic_id, "clinic_001")
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

  defp update_appointment_if_needed(invoice) do
    if invoice.appointment_id do
      # Get the appointment
      appointment = Clinicpro.Appointment.get(invoice.appointment_id)

      # Update appointment payment status if needed
      if appointment && invoice.status == "paid" do
        Clinicpro.Appointment.update(appointment, %{payment_status: "paid"})
      end
    end
  end
end
