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
        _active \\ true
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
  * `business_name` - Name of the business
  * `settlement_bank` - Bank code for settlements
  * `account_number` - Account number for settlements
  * `percentage_charge` - Percentage to charge on transactions
  * `description` - Optional description of the subaccount
  * `active` - Whether this subaccount should be active
  * `clinic_id` - ID of the clinic this subaccount belongs to

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def update_subaccount(
        subaccount_code,
        business_name,
        settlement_bank,
        account_number,
        percentage_charge,
        description \\ nil,
        active,
        _clinic_id
      ) do
    updates = %{
      business_name: business_name,
      settlement_bank: settlement_bank,
      account_number: account_number,
      percentage_charge: percentage_charge,
      description: description,
      active: active
    }

    # Get clinic_id from the subaccount metadata or use a default
    clinic_id = get_clinic_id_from_subaccount(subaccount_code) || 1

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
  * `perpage` - Number of results per page

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def list_subaccounts(clinic_id, page \\ 1, perpage \\ 50) do
    params = %{
      page: page,
      perPage: perpage
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

  defp get_clinic_config(_clinic_id) do
    # This would typically fetch the clinic's Paystack configuration from the database
    # For now, we'll use a simple mock implementation
    {:ok, %{secret_key: Application.get_env(:clinicpro, :paystack)[:secret_key]}}
  end

  defp get_clinic_email(clinic_id) do
    # This would typically fetch the clinic's email from the database
    # For now, we'll use a placeholder
    "clinic#{clinic_id}@clinicpro.com"
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
    case Http.get("/transaction/#{transaction_id}", get_secret_key(clinic_id)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack transaction fetch failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Lists transactions from Paystack with pagination.

  ## Parameters

  * `clinic_id` - ID of the clinic to list transactions for
  * `page` - Page number for pagination
  * `perpage` - Number of results per page
  * `filters` - Map of filters to apply (e.g., status, customer, amount)

  ## Returns

  * `{:ok, response}` - Successful response from Paystack
  * `{:error, reason}` - Error response
  """
  def list_transactions(clinic_id, page \\ 1, perpage \\ 50, filters \\ %{}) do
    params =
      Map.merge(
        %{
          page: page,
          perPage: perpage
        },
        filters
      )

    case Http.get("/transaction", get_secret_key(clinic_id), params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack transaction list failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Lists available banks for a country.

  ## Parameters

  * `country` - Country code (e.g., "nigeria", "ghana")
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, banks}` - List of banks
  * `{:error, reason}` - Error response
  """
  def list_banks(country \\ "nigeria", clinic_id) do
    case Http.get("/bank?country=#{country}", get_secret_key(clinic_id)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Paystack bank list fetch failed: #{inspect(body)}")
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        Logger.error("Paystack request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Helper function to get clinic_id from a subaccount
  defp get_clinic_id_from_subaccount(_subaccount_code) do
    # This would typically fetch the clinic ID from the subaccount in the database
    # For now, we'll use a default value
    1
  end

  defp maybe_add_subaccount(payload, nil), do: payload

  defp maybe_add_subaccount(payload, subaccount) do
    Map.put(payload, :subaccount, subaccount)
  end
end
