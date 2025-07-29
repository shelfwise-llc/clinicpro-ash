defmodule Clinicpro.PaystackLegacy do
  @moduledoc """
  Main module for Paystack integration.

  This module provides high-level functions for interacting with Paystack services,
  supporting multi-tenant architecture with per-clinic configurations.
  """

  alias Clinicpro.PaystackLegacy.{API, Subaccount, Transaction}

  @doc """
  Gets a subaccount by ID for a specific clinic.

  ## Parameters

  * `id` - The ID of the subaccount
  * `clinic_id` - The ID of the clinic

  ## Returns

  * `{:ok, subaccount}` - The subaccount
  * `{:error, reason}` - Error reason
  """
  def get_subaccount(id, clinic_id) do
    Subaccount.get_by_id_and_clinic(id, clinic_id)
  end

  @doc """
  Updates a subaccount for a specific clinic.

  ## Parameters

  * `id` - The ID of the subaccount
  * `attrs` - Attributes to update
  * `clinic_id` - The ID of the clinic

  ## Returns

  * `{:ok, subaccount}` - The updated subaccount
  * `{:error, reason}` - Error reason
  """
  def update_subaccount(id, attrs, clinic_id) do
    with {:ok, subaccount} <- Subaccount.get_by_id_and_clinic(id, clinic_id),
         {:ok, updated_subaccount} <- Subaccount.update(subaccount, attrs) do
      {:ok, updated_subaccount}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets transaction details with events from Paystack.

  ## Parameters

  * `transaction_id` - Paystack transaction ID
  * `clinic_id` - ID of the clinic that processed the payment

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def get_transaction_with_events(transaction_id, clinic_id) do
    API.get_transaction_with_events(transaction_id, clinic_id)
  end

  @doc """
  Initiates a payment transaction.

  ## Parameters

  * `attrs` - Map of transaction attributes

  ## Returns

  * `{:ok, transaction}` - The created transaction with authorization URL
  * `{:error, reason}` - Error reason
  """
  def initiate_payment(attrs) do
    clinic_id = attrs["clinic_id"] || attrs[:clinic_id]
    email = attrs["email"] || attrs[:email]
    amount = attrs["amount"] || attrs[:amount]
    reference = attrs["reference"] || attrs[:reference] || generate_reference()
    description = attrs["description"] || attrs[:description] || "Payment for clinic #{clinic_id}"

    callback_url =
      attrs["callback_url"] || attrs[:callback_url] || default_callback_url(clinic_id)

    metadata = attrs["metadata"] || attrs[:metadata] || %{}

    # Get active subaccount for the clinic if available
    subaccount_code =
      case Subaccount.getactive(clinic_id) do
        {:ok, subaccount} -> subaccount.subaccount_code
        _ -> nil
      end

    # Create transaction record in our database
    transaction_attrs = %{
      clinic_id: clinic_id,
      email: email,
      amount: amount,
      reference: reference,
      description: description,
      status: "pending",
      metadata: metadata
    }

    with {:ok, transaction} <- Transaction.create(transaction_attrs),
         {:ok, paystack_response} <-
           API.initialize_transaction(
             email,
             amount,
             reference,
             callback_url,
             metadata,
             subaccount_code,
             clinic_id
           ) do
      # Update transaction with Paystack response data
      transaction_update = %{
        authorization_url: paystack_response["data"]["authorization_url"],
        access_code: paystack_response["data"]["access_code"]
      }

      case Transaction.update(transaction, transaction_update) do
        {:ok, updated_transaction} -> {:ok, updated_transaction}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Lists transactions for a clinic with pagination and filtering.

  ## Parameters

  * `clinic_id` - The ID of the clinic
  * `page` - Page number
  * `perpage` - Items per page
  * `filters` - Map of filters to apply

  ## Returns

  * `{:ok, %{data: transactions, meta: pagination_metadata}}` - List of transactions with pagination metadata
  * `{:error, reason}` - Error reason
  """
  def list_transactions_paginated(clinic_id, page \\ 1, perpage \\ 50, filters \\ %{}) do
    # Calculate offset
    offset = (page - 1) * perpage

    # Get transactions from database
    transactions = Transaction.list_by_clinic(clinic_id, perpage, offset, filters)
    total_count = Transaction.count_by_clinic(clinic_id, filters)

    # Calculate pagination metadata
    total_pages = ceil(total_count / perpage)
    has_more = page < total_pages

    {:ok,
     %{
       data: transactions,
       meta: %{
         total: total_count,
         page: page,
         perpage: perpage,
         total_pages: total_pages,
         has_more: has_more
       }
     }}
  end

  @doc """
  Verifies a transaction from Paystack.

  ## Parameters

  * `reference` - Transaction reference
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, verified_transaction}` - The verified transaction
  * `{:error, reason}` - Error reason
  """
  def verify_transaction(reference, clinic_id) do
    with {:ok, transaction} <- get_transaction_by_reference(reference, clinic_id),
         {:ok, paystack_response} <- API.verify_transaction(reference, clinic_id) do
      # Update transaction with verification data
      paystack_data = paystack_response["data"]

      transaction_update = %{
        status: paystack_data["status"],
        paystack_reference: paystack_data["reference"],
        payment_date: parse_payment_date(paystack_data["paid_at"]),
        channel: paystack_data["channel"],
        currency: paystack_data["currency"],
        fees: paystack_data["fees"],
        gateway_response: paystack_data["gateway_response"]
      }

      Transaction.update(transaction, transaction_update)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp get_transaction_by_reference(reference, clinic_id) do
    case Transaction.get_by_reference(reference, clinic_id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  defp generate_reference do
    "clinicpro_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp default_callback_url(clinic_id) do
    # This would typically be configured per clinic
    # For now, we'll use a placeholder
    "https://clinicpro.com/payments/callback/#{clinic_id}"
  end

  defp parse_payment_date(nil), do: nil

  defp parse_payment_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  @doc """
  Extracts clinic ID from a Paystack reference string.

  References are expected to be in the format: "clinicpro_<random>_<clinic_id>"
  or contain the clinic_id in some other identifiable format.

  ## Parameters

  * `reference` - The reference string from Paystack

  ## Returns

  * `{:ok, clinic_id}` - Successfully extracted clinic ID
  * `{:error, :invalid_reference}` - Could not extract clinic ID
  """
  def extract_clinic_id_from_reference(reference) when is_binary(reference) do
    # Try to extract clinic_id from reference format "clinicpro_<random>_<clinic_id>"
    case String.split(reference, "_") do
      ["clinicpro", _random, clinic_id] ->
        case Integer.parse(clinic_id) do
          {id, ""} -> {:ok, id}
          _ -> {:error, :invalid_reference}
        end

      # Alternative format handling if needed
      _ ->
        # Fallback to regex pattern matching if needed
        case Regex.run(~r/clinic[_-]?(\d+)/i, reference) do
          [_, clinic_id] ->
            case Integer.parse(clinic_id) do
              {id, ""} -> {:ok, id}
              _ -> {:error, :invalid_reference}
            end

          _ ->
            {:error, :invalid_reference}
        end
    end
  end

  def extract_clinic_id_from_reference(_), do: {:error, :invalid_reference}
end
