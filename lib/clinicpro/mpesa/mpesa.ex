defmodule Clinicpro.MPesa do
  @moduledoc """
  Multi-tenant M-Pesa integration service for ClinicPro.

  This module serves as the main entry point for all M-Pesa operations,
  supporting multiple clinics with their own payment configurations.

  ## Examples

      # Initiate STK Push payment
      Clinicpro.MPesa.initiate_stk_push(clinic_id, phone, amount, reference, description)

      # Register C2B URLs for a clinic
      Clinicpro.MPesa.register_c2b_urls(clinic_id)
  """

  require Logger
  alias Clinicpro.MPesa.{Config, Auth, STKPush, C2B, Transaction, Callback}

  @doc """
  Initiates an STK push request for a specific clinic.

  ## Parameters

  - clinic_id: The ID of the clinic initiating the payment
  - phone: Customer's phone number
  - amount: Amount to be paid
  - reference: Your reference for this transaction
  - description: Transaction description

  ## Returns

  - {:ok, transaction} on success
  - {:error, reason} on failure
  """
  def initiate_stk_push(clinic_id, phone, amount, reference, description) do
    with {:ok, config} <- Config.get_for_clinic(clinic_id),
         {:ok, transaction} <- Transaction.create_pending(%{
           clinic_id: clinic_id,
           phone: phone,
           amount: amount,
           reference: reference,
           description: description,
           type: "stk_push"
         }),
         {:ok, response} <- STKPush.request(config, phone, amount, reference, description) do

      # Update transaction with M-Pesa request details
      Transaction.update(transaction, %{
        checkout_request_id: response["CheckoutRequestID"],
        merchant_request_id: response["MerchantRequestID"],
        raw_request: response
      })
    else
      {:error, :config_not_found} ->
        Logger.error("M-Pesa configuration not found for clinic #{clinic_id}")
        {:error, :mpesa_config_not_found}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Invalid transaction data: #{inspect(changeset.errors)}")
        {:error, :invalid_transaction_data}

      {:error, reason} ->
        Logger.error("M-Pesa STK push failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Registers C2B validation and confirmation URLs for a clinic.
  Must be called once after setting up a clinic's M-Pesa credentials.

  ## Parameters

  - clinic_id: The ID of the clinic to register URLs for

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def register_c2b_urls(clinic_id) do
    with {:ok, config} <- Config.get_for_clinic(clinic_id) do
      C2B.register_urls(config)
    else
      {:error, :config_not_found} ->
        Logger.error("M-Pesa configuration not found for clinic #{clinic_id}")
        {:error, :mpesa_config_not_found}

      {:error, reason} ->
        Logger.error("Failed to register C2B URLs: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Process a C2B callback from M-Pesa.

  This function is called by the callback controller when
  M-Pesa sends a payment notification.

  ## Parameters

  - payload: The callback payload from M-Pesa

  ## Returns

  - {:ok, transaction} on success
  - {:error, reason} on failure
  """
  def process_c2b_callback(payload) do
    Callback.process_c2b(payload)
  end

  @doc """
  Process an STK Push callback from M-Pesa.

  This function is called by the callback controller when
  M-Pesa sends an STK push result.

  ## Parameters

  - payload: The callback payload from M-Pesa

  ## Returns

  - {:ok, transaction} on success
  - {:error, reason} on failure
  """
  def process_stk_callback(payload) do
    Callback.process_stk(payload)
  end

  @doc """
  Query the status of an STK push transaction.

  ## Parameters

  - checkout_request_id: The CheckoutRequestID returned by the STK push request
  - clinic_id: The ID of the clinic that initiated the payment

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def query_stk_status(checkout_request_id, clinic_id) do
    with {:ok, config} <- Config.get_for_clinic(clinic_id),
         {:ok, transaction} <- Transaction.find_by_checkout_request_id(checkout_request_id),
         {:ok, response} <- STKPush.query_status(config, checkout_request_id) do

      # Update transaction with status response
      Transaction.update(transaction, %{
        result_code: response["ResultCode"],
        result_desc: response["ResultDesc"],
        raw_response: Map.merge(transaction.raw_response || %{}, %{"query_response" => response})
      })
    end
  end

  @doc """
  List transactions for a specific clinic with pagination.

  ## Parameters

  - clinic_id: The ID of the clinic to list transactions for
  - page: Page number (default: 1)
  - per_page: Number of transactions per page (default: 20)

  ## Returns

  - List of transactions
  """
  def list_transactions(clinic_id, page \\ 1, per_page \\ 20) do
    Transaction.list_for_clinic(clinic_id, page, per_page)
  end

  @doc """
  Get a transaction by its reference.

  ## Parameters

  - reference: The transaction reference

  ## Returns

  - {:ok, transaction} if found
  - {:error, :not_found} if not found
  """
  def get_transaction_by_reference(reference) do
    case Transaction.find_by_reference(reference) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end
end
