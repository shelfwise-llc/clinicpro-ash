defmodule Clinicpro.Paystack.API do
  @moduledoc """
  API module for Paystack integration.

  This module provides functions for interacting with the Paystack API,
  supporting multi-tenant architecture with per-clinic API keys.
  """

  require Logger
  alias Clinicpro.Paystack.Http

  @doc """
  Creates a new subaccount on Paystack.

  ## Parameters

  * `business_name` - Name of the business
  * `settlement_bank` - Bank code for settlements
  * `account_number` - Account number for settlements
  * `percentage_charge` - Percentage to charge on transactions
  * `description` - Optional description of the subaccount
  * `clinic_id` - ID of the clinic this subaccount belongs to
  * `active` - Whether this subaccount should be active

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def create_subaccount(
        business_name,
        settlement_bank,
        account_number,
        percentage_charge,
        description \\ nil,
        clinic_id,
        active \\ true
      ) do
    payload = %{
      business_name: business_name,
      settlement_bank: settlement_bank,
      account_number: account_number,
      percentage_charge: percentage_charge,
      description: description || "Clinic #{clinic_id} subaccount",
      primary_contact_email: get_clinic_email(clinic_id),
      metadata: %{
        clinic_id: clinic_id
      }
    }

    case Http.post("/subaccount", payload, get_secret_key(clinic_id)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack subaccount creation failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Updates an existing subaccount on Paystack.

  ## Parameters

  * `subaccount_code` - Paystack subaccount code
  * `updates` - Map of fields to update
  * `clinic_id` - ID of the clinic this subaccount belongs to

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def update_subaccount(subaccount_code, updates, clinic_id) do
    case Http.put("/subaccount/#{subaccount_code}", updates, get_secret_key(clinic_id)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack subaccount update failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches a subaccount from Paystack.

  ## Parameters

  * `subaccount_code` - Paystack subaccount code
  * `clinic_id` - ID of the clinic this subaccount belongs to

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def get_subaccount(subaccount_code, clinic_id) do
    case Http.get("/subaccount/#{subaccount_code}", get_secret_key(clinic_id)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack subaccount fetch failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Lists all subaccounts from Paystack.

  ## Parameters

  * `clinic_id` - ID of the clinic to get subaccounts for
  * `page` - Page number for pagination
  * `per_page` - Number of results per page

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def list_subaccounts(clinic_id, page \\ 1, per_page \\ 50) do
    params = %{
      page: page,
      perPage: per_page
    }

    case Http.get("/subaccount", get_secret_key(clinic_id), params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack subaccount list failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Initializes a transaction on Paystack.

  ## Parameters

  * `email` - Customer email
  * `amount` - Amount in kobo/cents
  * `reference` - Unique transaction reference
  * `callback_url` - URL to redirect to after payment
  * `metadata` - Additional data to include with the transaction
  * `subaccount` - Optional subaccount to split payment with
  * `clinic_id` - ID of the clinic processing the payment

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def initialize_transaction(
        email,
        amount,
        reference,
        callback_url,
        metadata,
        subaccount \\ nil,
        clinic_id
      ) do
    payload =
      %{
        email: email,
        amount: amount,
        reference: reference,
        callback_url: callback_url,
        metadata: metadata
      }
      |> maybe_add_subaccount(subaccount)

    case Http.post("/transaction/initialize", payload, get_secret_key(clinic_id)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack transaction initialization failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Verifies a transaction on Paystack.

  ## Parameters

  * `reference` - Transaction reference to verify
  * `clinic_id` - ID of the clinic that processed the payment

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def verify_transaction(reference, clinic_id) do
    case Http.get("/transaction/verify/#{reference}", get_secret_key(clinic_id)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack transaction verification failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp get_secret_key(clinic_id) do
    # Get the secret key for the specific clinic from the configuration
    # This supports multi-tenant architecture with per-clinic API keys
    case get_clinic_config(clinic_id) do
      {:ok, config} ->
        config.secret_key

      _error ->
        # Fall back to the default secret key
        Application.get_env(:clinicpro, :paystack)[:secret_key]
    end
  end

  defp get_clinic_config(clinic_id) do
    # This would typically fetch the clinic's Paystack configuration from the database
    # For now, we'll use a simple mock implementation
    {:ok, %{secret_key: Application.get_env(:clinicpro, :paystack)[:secret_key]}}
  end

  defp get_clinic_email(clinic_id) do
    # This would typically fetch the clinic's email from the database
    # For now, we'll use a placeholder
    "clinic#{clinic_id}@clinicpro.com"
  end

  defp maybe_add_subaccount(payload, nil), do: payload

  defp maybe_add_subaccount(payload, subaccount) do
    Map.put(payload, :subaccount, subaccount)
  end
end