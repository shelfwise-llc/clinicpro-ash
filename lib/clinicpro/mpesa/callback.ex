defmodule Clinicpro.MPesa.Callback do
  @moduledoc """
  Handles M-Pesa callback processing with multi-tenant support.
  This module processes callbacks from Safaricom's M-Pesa API,
  ensuring proper isolation between clinics.
  """

  require Logger
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Invoices.PaymentProcessor

  @doc """
  Processes an STK Push callback from M-Pesa.

  ## Parameters

  - `params` - The callback parameters from M-Pesa

  ## Returns

  - `{:ok, transaction}` - If the callback was processed successfully
  - `{:error, reason}` - If the callback processing failed
  """
  def process_stk_callback(params) do
    # Extract the necessary data from the callback
    with {:ok, data} <- extract_stk_callback_data(params),
         {:ok, transaction} <- find_transaction(data),
         :ok <- validate_clinic_transaction(transaction, data),
         {:ok, updated_transaction} <- update_transaction_status(transaction, data) do

      # Process payment if successful
      if data.result_code == "0" do
        process_successful_payment(updated_transaction)
      else
        process_failed_payment(updated_transaction)
      end

      {:ok, updated_transaction}
    else
      error ->
        Logger.error("Failed to process STK callback: #{inspect(error)}")
        error
    end
  end

  @doc """
  Processes a C2B confirmation callback from M-Pesa.

  ## Parameters

  - `params` - The callback parameters from M-Pesa

  ## Returns

  - `{:ok, transaction}` - If the callback was processed successfully
  - `{:error, reason}` - If the callback processing failed
  """
  def process_c2b_confirmation(params) do
    # Extract the necessary data from the callback
    with {:ok, data} <- extract_c2b_callback_data(params),
         {:ok, transaction} <- find_or_create_c2b_transaction(data),
         :ok <- validate_clinic_transaction(transaction, data),
         {:ok, updated_transaction} <- update_transaction_status(transaction, data) do

      # Process payment (C2B confirmations are always successful)
      process_successful_payment(updated_transaction)

      {:ok, updated_transaction}
    else
      error ->
        Logger.error("Failed to process C2B confirmation: #{inspect(error)}")
        error
    end
  end

  # Private functions

  defp extract_stk_callback_data(params) do
    body = params["Body"] || %{}
    stkCallback = body["stkCallback"] || %{}

    # Extract metadata to get clinic_id and invoice_id
    metadata =
      case stkCallback["CallbackMetadata"] do
        %{"Item" => items} -> extract_metadata_items(items)
        _ -> %{}
      end

    # Extract merchant request ID and checkout request ID
    merchant_request_id = stkCallback["MerchantRequestID"]
    checkout_request_id = stkCallback["CheckoutRequestID"]
    result_code = to_string(stkCallback["ResultCode"])
    result_description = stkCallback["ResultDesc"]

    # Return the extracted data
    {:ok, %{
      merchant_request_id: merchant_request_id,
      checkout_request_id: checkout_request_id,
      result_code: result_code,
      result_description: result_description,
      transaction_id: metadata["TransID"],
      transaction_date: metadata["TransactionDate"],
      phone_number: metadata["PhoneNumber"],
      amount: metadata["Amount"]
    }}
  end

  defp extract_c2b_callback_data(params) do
    # Extract the necessary data from the C2B callback
    transaction_type = params["TransactionType"]
    transaction_id = params["TransID"]
    transaction_time = params["TransTime"]
    amount = params["TransAmount"]
    phone_number = params["MSISDN"]
    shortcode = params["BusinessShortCode"]
    reference = params["BillRefNumber"]
    invoice_id = reference

    # Determine clinic_id from the shortcode
    # This assumes you have a way to map shortcodes to clinic_ids
    clinic_id = get_clinic_id_from_shortcode(shortcode)

    if clinic_id do
      {:ok, %{
        transaction_type: transaction_type,
        transaction_id: transaction_id,
        transaction_date: transaction_time,
        amount: amount,
        phone_number: phone_number,
        shortcode: shortcode,
        reference: reference,
        invoice_id: invoice_id,
        clinic_id: clinic_id,
        result_code: "0", # C2B confirmations are always successful
        result_description: "Success"
      }}
    else
      {:error, :invalid_shortcode}
    end
  end

  defp extract_metadata_items(items) do
    Enum.reduce(items, %{}, fn item, acc ->
      name = item["Name"]
      value = item["Value"]
      Map.put(acc, name, value)
    end)
  end

  defp find_transaction(%{checkout_request_id: checkout_request_id, merchant_request_id: merchant_request_id}) do
    # Try to find by checkout request ID first
    case Transaction.get_by_checkout_request_id(checkout_request_id, nil) do
      nil ->
        # If not found, try by merchant request ID
        case Transaction.get_by_merchant_request_id(merchant_request_id, nil) do
          nil -> {:error, :transaction_not_found}
          transaction -> {:ok, transaction}
        end
      transaction ->
        {:ok, transaction}
    end
  end

  defp find_or_create_c2b_transaction(%{transaction_id: transaction_id, clinic_id: clinic_id} = data) do
    # Try to find by transaction ID first
    case Transaction.get_by_transaction_id(transaction_id, clinic_id) do
      nil ->
        # If not found, create a new transaction
        attrs = %{
          clinic_id: data.clinic_id,
          invoice_id: data.invoice_id,
          patient_id: get_patient_id_from_invoice(data.invoice_id, data.clinic_id),
          amount: data.amount,
          phone_number: data.phone_number,
          status: "completed",
          transaction_id: data.transaction_id,
          reference: data.reference,
          result_code: data.result_code,
          result_description: data.result_description,
          merchant_request_id: "C2B-#{data.transaction_id}",
          checkout_request_id: "C2B-#{data.transaction_id}"
        }

        case Transaction.create(attrs) do
          {:ok, transaction} -> {:ok, transaction}
          {:error, _} = error -> error
        end
      transaction ->
        {:ok, transaction}
    end
  end

  defp validate_clinic_transaction(transaction, %{clinic_id: clinic_id}) when not is_nil(clinic_id) do
    if transaction.clinic_id == clinic_id do
      :ok
    else
      {:error, :clinic_mismatch}
    end
  end

  defp validate_clinic_transaction(_transaction, _data), do: :ok

  defp update_transaction_status(transaction, %{result_code: "0"} = data) do
    # Update transaction for successful payment
    attrs = %{
      status: "completed",
      transaction_id: data.transaction_id,
      result_code: data.result_code,
      result_description: data.result_description
    }

    Transaction.update(transaction, attrs)
  end

  defp update_transaction_status(transaction, data) do
    # Update transaction for failed payment
    attrs = %{
      status: "failed",
      result_code: data.result_code,
      result_description: data.result_description
    }

    Transaction.update(transaction, attrs)
  end

  defp process_successful_payment(transaction) do
    # Get the payment processor module
    payment_processor = Application.get_env(:clinicpro, :payment_processor, PaymentProcessor)

    # Process the payment
    payment_processor.process_completed_payment(
      transaction.invoice_id,
      transaction.clinic_id,
      %{
        transaction_id: transaction.transaction_id,
        amount: transaction.amount,
        phone_number: transaction.phone_number
      }
    )
  end

  defp process_failed_payment(transaction) do
    # Get the payment processor module
    payment_processor = Application.get_env(:clinicpro, :payment_processor, PaymentProcessor)

    # Process the failed payment
    payment_processor.process_failed_payment(
      transaction.invoice_id,
      transaction.clinic_id,
      %{
        result_code: transaction.result_code,
        result_description: transaction.result_description
      }
    )
  end

  defp get_clinic_id_from_shortcode(shortcode) do
    # Query the database to find the clinic with this shortcode
    # This is a simplified example - you would need to implement this based on your schema
    import Ecto.Query
    case Clinicpro.Repo.one(from c in Clinicpro.MPesa.Config, where: c.shortcode == ^shortcode) do
      nil -> nil
      config -> config.clinic_id
    end
  end

  defp get_patient_id_from_invoice(invoice_id, clinic_id) do
    # Query the database to find the patient ID associated with this invoice
    # This is a simplified example - you would need to implement this based on your schema
    case Clinicpro.Invoices.get_invoice(invoice_id, clinic_id) do
      nil -> nil
      invoice -> invoice.patient_id
    end
  end
end
