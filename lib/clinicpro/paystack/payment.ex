defmodule Clinicpro.Paystack.Payment do
  @moduledoc """
  Module for handling Paystack payment operations.

  This module provides functions for initializing transactions, verifying payments,
  and other payment-related operations with Paystack.
  """

  alias Clinicpro.Paystack.{Config, SubAccount}
  alias Clinicpro.Paystack.Http

  @doc """
  Initializes a _transaction with Paystack.

  ## Parameters

  - `email` - The customer's email address
  - `amount` - The amount to charge in the smallest currency unit (kobo for NGN, cents for USD)
  - `reference` - The reference for the _transaction (usually invoice number)
  - `description` - Description of the _transaction
  - `_clinic_id` - The ID of the clinic initiating the payment
  - `metadata` - Additional metadata for the _transaction (optional)

  ## Returns

  - `{:ok, %{authorization_url: url, access_code: code, reference: ref}}` - If successful
  - `{:error, reason}` - If failed
  """
  def initialize_transaction(email, amount, reference, description, _clinic_id, metadata \\ %{}) do
    with {:ok, secret_key} <- Config.get_secret_key(_clinic_id),
         {:ok, subaccount} <- get_clinic_subaccount(_clinic_id) do

      # Build the payload
      payload = %{
        email: email,
        amount: amount,
        reference: reference,
        callback_url: get_callback_url(_clinic_id),
        metadata: Map.merge(metadata, %{_clinic_id: _clinic_id}),
        subaccount: subaccount.subaccount_code,
        transaction_charge: subaccount.percentage_charge
      }

      # Make the API call
      case Http.post("/_transaction/initialize", payload, secret_key) do
        {:ok, %{"status" => true, "data" => data}} ->
          {:ok, %{
            authorization_url: data["authorization_url"],
            access_code: data["access_code"],
            reference: data["reference"]
          }}

        {:ok, %{"status" => false, "message" => message}} ->
          {:error, message}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Verifies a _transaction with Paystack.

  ## Parameters

  - `reference` - The reference to verify
  - `_clinic_id` - The ID of the clinic that initiated the payment

  ## Returns

  - `{:ok, verification_data}` - If successful
  - `{:error, reason}` - If failed
  """
  def verify_transaction(reference, _clinic_id) do
    with {:ok, secret_key} <- Config.get_secret_key(_clinic_id) do
      case Http.get("/_transaction/verify/#{reference}", secret_key) do
        {:ok, %{"status" => true, "data" => data}} ->
          # Extract relevant verification data
          verification_data = %{
            status: if(data["status"] == "success", do: "completed", else: "failed"),
            paid_at: data["paid_at"],
            channel: data["channel"],
            currency: data["currency"],
            fees: data["fees"],
            gateway_response: data["gateway_response"]
          }

          {:ok, verification_data}

        {:ok, %{"status" => false, "message" => message}} ->
          {:error, message}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Lists all banks supported by Paystack.

  ## Returns

  - `{:ok, banks}` - List of supported banks
  - `{:error, reason}` - If the request failed
  """
  def list_banks do
    # Use a default secret key for this operation as it doesn't require clinic-specific auth
    {:ok, secret_key} = get_default_secret_key()

    case Http.get("/bank", secret_key) do
      {:ok, %{"status" => true, "data" => data}} ->
        {:ok, data}

      {:ok, %{"status" => false, "message" => message}} ->
        {:error, message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Resolves an account number to get account details.

  ## Parameters

  - `account_number` - The account number to resolve
  - `bank_code` - The bank code

  ## Returns

  - `{:ok, account_data}` - If successful
  - `{:error, reason}` - If failed
  """
  def resolve_account_number(account_number, bank_code) do
    # Use a default secret key for this operation as it doesn't require clinic-specific auth
    {:ok, secret_key} = get_default_secret_key()

    case Http.get("/bank/resolve?account_number=#{account_number}&bank_code=#{bank_code}", secret_key) do
      {:ok, %{"status" => true, "data" => data}} ->
        {:ok, data}

      {:ok, %{"status" => false, "message" => message}} ->
        {:error, message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp get_clinic_subaccount(_clinic_id) do
    case SubAccount.get_active_subaccount(_clinic_id) do
      {:ok, subaccount} -> {:ok, subaccount}
      {:error, :no_active_subaccount} -> {:error, :no_active_subaccount}
    end
  end

  defp get_callback_url(_clinic_id) do
    case Config.get_active_config(_clinic_id) do
      {:ok, config} -> config.webhook_url
      _ -> Application.get_env(:clinicpro, :paystack_default_callback_url)
    end
  end

  defp get_default_secret_key do
    case Application.get_env(:clinicpro, :paystack_default_secret_key) do
      nil -> {:error, :no_default_secret_key}
      key -> {:ok, key}
    end
  end
end
