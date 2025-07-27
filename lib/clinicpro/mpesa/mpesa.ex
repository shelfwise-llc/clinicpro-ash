defmodule Clinicpro.MPesa do
  @moduledoc """
  Main M-Pesa module that provides a unified interface for M-Pesa operations.

  IMPORTANT: M-Pesa integration is currently disabled. All operations will return
  {:error, :mpesa_disabled} and log the attempt.
  """

  require Logger
  alias Clinicpro.MPesa.Disabled

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
  def initiate_stk_push(phone_number, amount, reference, description, clinic_id) do
    # Log the attempt and return disabled error
    Logger.info("Attempted to use disabled M-Pesa STK Push: phone=#{phone_number}, amount=#{amount}, reference=#{reference}, clinic_id=#{clinic_id}")
    Disabled.initiate_stk_push(%{
      phone_number: phone_number,
      amount: amount,
      reference: reference,
      description: description,
      clinic_id: clinic_id
    })
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
  def check_stk_push_status(checkout_request_id, clinic_id) do
    # Log the attempt and return disabled error
    Logger.info("Attempted to check disabled M-Pesa STK Push status: checkout_request_id=#{checkout_request_id}, clinic_id=#{clinic_id}")
    Disabled.query_stk_status(checkout_request_id, nil)
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
    # Log the attempt and return disabled error
    Logger.info("Attempted to process disabled M-Pesa STK callback: #{inspect(params)}")
    Disabled.disabled_operation("process_stk_callback")
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
  def get_transaction_by_checkout_request_id(checkout_request_id, clinic_id) do
    Logger.info("Attempted to get disabled M-Pesa transaction by checkout_request_id: #{checkout_request_id}, clinic_id=#{clinic_id}")
    Disabled.get_transaction(checkout_request_id)
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
  def get_transaction_by_merchant_request_id(merchant_request_id, clinic_id) do
    Logger.info("Attempted to get disabled M-Pesa transaction by merchant_request_id: #{merchant_request_id}, clinic_id=#{clinic_id}")
    Disabled.get_transaction(merchant_request_id)
  end

  @doc """
  Lists all transactions for a specific clinic.

  ## Parameters

  - `_clinic_id` - The ID of the clinic to list transactions for

  ## Returns

  - List of transactions
  """
  def list_transactions_by_clinic(clinic_id) do
    Logger.info("Attempted to list disabled M-Pesa transactions for clinic: #{clinic_id}")
    Disabled.list_transactions("clinic", clinic_id)
  end

  @doc """
  Lists all transactions for a specific invoice.

  ## Parameters

  - `invoice_id` - The ID of the invoice to list transactions for

  ## Returns

  - List of transactions
  """
  def list_transactions_by_invoice(invoice_id) do
    Logger.info("Attempted to list disabled M-Pesa transactions for invoice: #{invoice_id}")
    Disabled.list_transactions("invoice", invoice_id)
  end

  @doc """
  Lists all transactions for a specific patient within a clinic.

  ## Parameters

  - `patient_id` - The ID of the patient to list transactions for
  - `_clinic_id` - The ID of the clinic (for multi-tenant support)

  ## Returns

  - List of transactions
  """
  def list_transactions_by_patient(patient_id, clinic_id) do
    Logger.info("Attempted to list disabled M-Pesa transactions for patient: #{patient_id}, clinic_id=#{clinic_id}")
    Disabled.list_transactions("patient", patient_id)
  end

  @doc """
  Gets the M-Pesa configuration for a specific clinic.

  ## Parameters

  - `_clinic_id` - The ID of the clinic to get the configuration for

  ## Returns

  - `config` - The configuration for the clinic
  """
  def get_config(clinic_id) do
    Logger.info("Attempted to get disabled M-Pesa configuration for clinic: #{clinic_id}")
    Disabled.get_config(clinic_id)
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
  def update_config(clinic_id, attrs) do
    Logger.info("Attempted to update disabled M-Pesa configuration for clinic: #{clinic_id}, attrs: #{inspect(attrs)}")
    Disabled.update_config(clinic_id, attrs)
  end

  # Private functions are no longer needed as all operations are disabled
end
