defmodule Clinicpro.MPesa.Callback do
  @moduledoc """
  Handles M-Pesa callback processing with multi-tenant support.
  This module processes callbacks from Safaricom's M-Pesa API,
  ensuring proper isolation between clinics.
  """

  require Logger
  # # alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Invoices.PaymentProcessor

  @doc """
  Processes an STK Push callback from M-Pesa.

  ## Parameters

  - `params` - The callback parameters from M-Pesa

  ## Returns

  - `{:ok, _transaction}` - If the callback was processed successfully
  - `{:error, reason}` - If the callback processing failed
  """
  def process_stk_callback(params) do
    # Extract the necessary data from the callback
    with {:ok, data} <- extract_stk_callback_data(params),
         {:ok, _transaction} <- find_transaction(data),
         :ok <- validate_clinic_transaction(_transaction, data),
         {:ok, updated_transaction} <- update_transaction_status(_transaction, data) do

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

  - `{:ok, _transaction}` - If the callback was processed successfully
  - `{:error, reason}` - If the callback processing failed
  """
  def process_c2b_confirmation(params) do
    # Extract the necessary data from the callback
    with {:ok, data} <- extract_c2b_callback_data(params),
         {:ok, _transaction} <- find_or_create_c2b_transaction(data),
         :ok <- validate_clinic_transaction(_transaction, data),
         {:ok, updated_transaction} <- update_transaction_status(_transaction, data) do

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

    # Extract metadata to get _clinic_id and invoice_id
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

    # Determine _clinic_id from the shortcode
    # This assumes you have a way to map shortcodes to clinic_ids
    _clinic_id = get_clinic_id_from_shortcode(shortcode)

    if _clinic_id do
      {:ok, %{
        transaction_type: transaction_type,
        transaction_id: transaction_id,
        transaction_date: transaction_time,
        amount: amount,
        phone_number: phone_number,
        shortcode: shortcode,
        reference: reference,
        invoice_id: invoice_id,
        _clinic_id: _clinic_id,
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
          _transaction -> {:ok, _transaction}
        end
      _transaction ->
        {:ok, _transaction}
    end
  end

  defp find_or_create_c2b_transaction(%{transaction_id: transaction_id, _clinic_id: _clinic_id} = data) do
    # Try to find by _transaction ID first
    case Transaction.get_by_transaction_id(transaction_id, _clinic_id) do
      nil ->
        # If not found, create a new _transaction
        attrs = %{
          _clinic_id: data._clinic_id,
          invoice_id: data.invoice_id,
          patient_id: get_patient_id_from_invoice(data.invoice_id, data._clinic_id),
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
          {:ok, _transaction} -> {:ok, _transaction}
          {:error, _} = error -> error
        end
      _transaction ->
        {:ok, _transaction}
    end
  end

  defp validate_clinic_transaction(_transaction, %{_clinic_id: _clinic_id}) when not is_nil(_clinic_id) do
    if _transaction._clinic_id == _clinic_id do
      :ok
    else
      {:error, :clinic_mismatch}
    end
  end

  defp validate_clinic_transaction(_transaction, _data), do: :ok

  defp update_transaction_status(_transaction, %{result_code: "0"} = data) do
    # Update _transaction for successful payment
    attrs = %{
      status: "completed",
      transaction_id: data.transaction_id,
      result_code: data.result_code,
      result_description: data.result_description
    }

    Transaction.update(_transaction, attrs)
  end

  defp update_transaction_status(_transaction, data) do
    # Update _transaction for failed payment
    attrs = %{
      status: "failed",
      result_code: data.result_code,
      result_description: data.result_description
    }

    Transaction.update(_transaction, attrs)
  end

  defp process_successful_payment(_transaction) do
    # Get the payment processor module
    payment_processor = Application.get_env(:clinicpro, :payment_processor, PaymentProcessor)

    # Process the payment
    payment_processor.process_completed_payment(
      _transaction.invoice_id,
      _transaction._clinic_id,
      %{
        transaction_id: _transaction.transaction_id,
        amount: _transaction.amount,
        phone_number: _transaction.phone_number
      }
    )
  end

  defp process_failed_payment(_transaction) do
    # Get the payment processor module
    payment_processor = Application.get_env(:clinicpro, :payment_processor, PaymentProcessor)

    # Process the failed payment
    payment_processor.process_failed_payment(
      _transaction.invoice_id,
      _transaction._clinic_id,
      %{
        result_code: _transaction.result_code,
        result_description: _transaction.result_description
      }
    )
  end

  defp get_clinic_id_from_shortcode(shortcode) do
    # Query the database to find the clinic with this shortcode
    # This is a simplified example - you would need to implement this based on your schema
    import Ecto.Query
    case Clinicpro.Repo.one(from c in Clinicpro.MPesa.Config, where: c.shortcode == ^shortcode) do
      nil -> nil
      config -> config._clinic_id
    end
  end

  defp get_patient_id_from_invoice(invoice_id, _clinic_id) do
    # Query the database to find the patient ID associated with this invoice
    # This is a simplified example - you would need to implement this based on your schema
    case Clinicpro.Invoices.get_invoice(invoice_id, _clinic_id) do
      nil -> nil
      invoice -> invoice.patient_id
    end
  end
end
