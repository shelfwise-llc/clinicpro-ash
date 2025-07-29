defmodule Clinicpro.PaystackLegacy.Transaction do
  @moduledoc """
  Legacy Transaction module for Paystack integration.
  
  This module provides legacy Paystack Transaction functions for backward compatibility.
  It delegates to the new Paystack Transaction implementation following Paystack's official API.
  """

  require Logger
  alias Clinicpro.Paystack.Transaction, as: NewTransaction
  alias Clinicpro.Paystack.API, as: PaystackAPI

  @doc """
  Initializes a payment transaction.
  
  Following Paystack's official API documentation for transaction initialization.
  See: https://paystack.com/docs/api/transaction/#initialize
  
  ## Parameters
  
  * `email` - Customer's email address
  * `amount` - Amount in the smallest currency unit (e.g., kobo for NGN)
  * `reference` - Unique transaction reference
  * `callback_url` - URL to redirect after payment
  * `metadata` - Additional data for the transaction
  * `clinic_id` - ID of the clinic processing the payment
  
  ## Returns
  
  * `{:ok, response}` - Success response with authorization URL
  * `{:error, reason}` - Error reason
  """
  def initialize_payment(email, amount, reference, callback_url, metadata, clinic_id) do
    if function_exported?(NewTransaction, :initialize_payment, 6) do
      NewTransaction.initialize_payment(email, amount, reference, callback_url, metadata, clinic_id)
    else
      # Fallback to direct API call
      PaystackAPI.initialize_transaction(email, amount, reference, callback_url, metadata, nil, clinic_id)
    end
  end

  @doc """
  Verifies a payment transaction.
  
  Following Paystack's official API documentation for transaction verification.
  See: https://paystack.com/docs/api/transaction/#verify
  
  ## Parameters
  
  * `reference` - Transaction reference to verify
  * `clinic_id` - ID of the clinic that processed the payment
  
  ## Returns
  
  * `{:ok, transaction}` - Success response with transaction details
  * `{:error, reason}` - Error reason
  """
  def verify_payment(reference, clinic_id) do
    if function_exported?(NewTransaction, :verify_payment, 2) do
      NewTransaction.verify_payment(reference, clinic_id)
    else
      # Fallback to direct API call
      PaystackAPI.verify_transaction(reference, clinic_id)
    end
  end

  @doc """
  Gets transaction statistics for a clinic.
  
  ## Parameters
  
  * `clinic_id` - ID of the clinic
  
  ## Returns
  
  * `{:ok, stats}` - Success response with transaction stats
  * `{:error, reason}` - Error reason
  """
  def get_stats(clinic_id) do
    if function_exported?(NewTransaction, :get_stats, 1) do
      NewTransaction.get_stats(clinic_id)
    else
      Logger.warning("NewTransaction.get_stats/1 not implemented, returning empty stats")
      {:ok, %{total_count: 0, total_amount: 0, successful_count: 0, successful_amount: 0}}
    end
  end
end