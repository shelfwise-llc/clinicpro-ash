defmodule Clinicpro.MPesa do
  @moduledoc """
  Main M-Pesa module that provides a unified interface for M-Pesa operations.

  This module coordinates all M-Pesa functionality with multi-tenant support,
  ensuring proper isolation between clinics. It serves as the primary entry point
  for M-Pesa operations in the ClinicPro application.
  """

  alias Clinicpro.MPesa.{
    STKPush,
    Config,
    Transaction,
    Callback
  }

  @doc """
  Initiates an STK Push payment request.

  ## Parameters

  - `phone_number` - The phone number to send the STK Push to
  - `amount` - The amount to charge
  - `reference` - The reference for the _transaction (usually invoice number)
  - `description` - Description of the _transaction
  - `_clinic_id` - The ID of the clinic initiating the payment

  ## Returns

  - `{:ok, %{checkout_request_id: id, _transaction: _transaction}}` - If the request was successful
  - `{:error, reason}` - If the request failed
  """
  def initiate_stk_push(phone_number, amount, reference, description, _clinic_id) do
    # Create a pending _transaction
    with {:ok, _transaction} <- create_pending_transaction(phone_number, amount, reference, description, _clinic_id),
         # Get the STK Push module (allows for mocking in tests)
         stk_push_module <- get_stk_push_module(),
         # Send the STK Push request
         {:ok, response} <- stk_push_module.send_stk_push(phone_number, amount, reference, description, _clinic_id) do

      # Update the _transaction with the checkout request ID and merchant request ID
      {:ok, updated_transaction} = Transaction.update(_transaction, %{
        checkout_request_id: response.checkout_request_id,
        merchant_request_id: response.merchant_request_id
      })

      # Return the checkout request ID and _transaction
      {:ok, %{
        checkout_request_id: response.checkout_request_id,
        _transaction: updated_transaction
      }}
    end
  end

  @doc """
  Checks the status of an STK Push payment.

  ## Parameters

  - `checkout_request_id` - The checkout request ID to check
  - `_clinic_id` - The ID of the clinic that initiated the payment

  ## Returns

  - `{:ok, _transaction}` - If the _transaction was found
  - `{:error, reason}` - If the _transaction was not found or the status check failed
  """
  def check_stk_push_status(checkout_request_id, _clinic_id) do
    # Get the _transaction
    case Transaction.get_by_checkout_request_id(checkout_request_id, _clinic_id) do
      nil ->
        {:error, :transaction_not_found}

      _transaction ->
        # If the _transaction is still pending, check with M-Pesa
        if _transaction.status == "pending" do
          # Get the STK Push module
          stk_push_module = get_stk_push_module()

          # Check the status with M-Pesa
          case stk_push_module.query_stk_push_status(checkout_request_id, _transaction.merchant_request_id, _clinic_id) do
            {:ok, status_response} ->
              # Update the _transaction based on the status response
              update_transaction_from_status(_transaction, status_response)

            {:error, _reason} ->
              # If the status check fails, just return the _transaction as is
              {:ok, _transaction}
          end
        else
          # If the _transaction is not pending, just return it
          {:ok, _transaction}
        end
    end
  end

  @doc """
  Processes an STK Push callback from M-Pesa.

  ## Parameters

  - `params` - The callback parameters from M-Pesa

  ## Returns

  - `{:ok, _transaction}` - If the callback was processed successfully
  - `{:error, reason}` - If the callback processing failed
  """
  def process_stk_callback(params) do
    Callback.process_stk_callback(params)
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
    Callback.process_c2b_confirmation(params)
  end

  @doc """
  Gets a _transaction by its checkout request ID.

  ## Parameters

  - `checkout_request_id` - The checkout request ID to search for
  - `_clinic_id` - The ID of the clinic that initiated the payment

  ## Returns

  - `_transaction` - If the _transaction was found
  - `nil` - If the _transaction was not found
  """
  def get_transaction_by_checkout_request_id(checkout_request_id, _clinic_id) do
    Transaction.get_by_checkout_request_id(checkout_request_id, _clinic_id)
  end

  @doc """
  Gets a _transaction by its merchant request ID.

  ## Parameters

  - `merchant_request_id` - The merchant request ID to search for
  - `_clinic_id` - The ID of the clinic that initiated the payment

  ## Returns

  - `_transaction` - If the _transaction was found
  - `nil` - If the _transaction was not found
  """
  def get_transaction_by_merchant_request_id(merchant_request_id, _clinic_id) do
    Transaction.get_by_merchant_request_id(merchant_request_id, _clinic_id)
  end

  @doc """
  Lists all transactions for a specific clinic.

  ## Parameters

  - `_clinic_id` - The ID of the clinic to list transactions for

  ## Returns

  - List of transactions
  """
  def list_transactions_by_clinic(_clinic_id) do
    Transaction.list_by_clinic_id(_clinic_id)
  end

  @doc """
  Lists all transactions for a specific invoice.

  ## Parameters

  - `invoice_id` - The ID of the invoice to list transactions for

  ## Returns

  - List of transactions
  """
  def list_transactions_by_invoice(invoice_id) do
    Transaction.list_by_invoice_id(invoice_id)
  end

  @doc """
  Lists all transactions for a specific patient within a clinic.

  ## Parameters

  - `patient_id` - The ID of the patient to list transactions for
  - `_clinic_id` - The ID of the clinic (for multi-tenant support)

  ## Returns

  - List of transactions
  """
  def list_transactions_by_patient(patient_id, _clinic_id) do
    Transaction.list_by_patient_id(patient_id, _clinic_id)
  end

  @doc """
  Gets the M-Pesa configuration for a specific clinic.

  ## Parameters

  - `_clinic_id` - The ID of the clinic to get the configuration for

  ## Returns

  - `config` - The configuration for the clinic
  """
  def get_config(_clinic_id) do
    Config.get_config(_clinic_id)
  end

  @doc """
  Updates the M-Pesa configuration for a specific clinic.

  ## Parameters

  - `_clinic_id` - The ID of the clinic to update the configuration for
  - `attrs` - Map of attributes to update

  ## Returns

  - `{:ok, config}` - If the configuration was updated successfully
  - `{:error, changeset}` - If the configuration update failed
  """
  def update_config(_clinic_id, attrs) do
    case Config.get_by_clinic_id(_clinic_id) do
      nil ->
        # If no configuration exists, create a new one
        Config.create(Map.put(attrs, :_clinic_id, _clinic_id))

      config ->
        # If a configuration exists, update it
        Config.update(config, attrs)
    end
  end

  # Private functions

  defp create_pending_transaction(phone_number, amount, reference, description, _clinic_id) do
    # Extract invoice_id and patient_id from reference
    # This assumes that reference is the invoice ID
    invoice_id = reference
    patient_id = get_patient_id_from_invoice(invoice_id, _clinic_id)

    # Create the _transaction
    Transaction.create(%{
      _clinic_id: _clinic_id,
      invoice_id: invoice_id,
      patient_id: patient_id,
      amount: amount,
      phone_number: phone_number,
      status: "pending",
      reference: reference,
      merchant_request_id: "",
      checkout_request_id: "",
      result_code: "",
      result_description: description
    })
  end

  defp update_transaction_from_status(_transaction, status_response) do
    # Extract the result code and description
    result_code = status_response.result_code
    result_description = status_response.result_desc

    # Determine the new status
    new_status = if result_code == "0", do: "completed", else: "failed"

    # Update the _transaction
    attrs = %{
      status: new_status,
      result_code: result_code,
      result_description: result_description
    }

    # Add transaction_id if available
    attrs = if Map.has_key?(status_response, :transaction_id) do
      Map.put(attrs, :transaction_id, status_response.transaction_id)
    else
      attrs
    end

    # Update the _transaction
    Transaction.update(_transaction, attrs)
  end

  defp get_stk_push_module do
    Application.get_env(:clinicpro, :stk_push_module, STKPush)
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
