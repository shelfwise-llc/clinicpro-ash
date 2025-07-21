defmodule Clinicpro.MPesa.Auth do
  @moduledoc """
  Handles authentication with the M-Pesa API.

  This module is responsible for:
  1. Obtaining access tokens from the M-Pesa API
  2. Caching tokens to reduce API calls
  3. Handling token expiration and refresh
  """

  require Logger
  alias Clinicpro.MPesa.Helpers

  @sandbox_auth_url "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
  @prod_auth_url "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"

  # Token cache with ETS
  @table_name :mpesa_tokens

  @doc """
  Gets an access token for the M-Pesa API.
  Uses cached token if available and not expired.

  ## Parameters

  - config: M-Pesa configuration for the clinic

  ## Returns

  - {:ok, token} on success
  - {:error, reason} on failure
  """
  def get_access_token(config) do
    # Initialize ETS table if not exists
    ensure_table_exists()

    # Generate cache key based on credentials
    cache_key = "#{config.consumer_key}:#{config.consumer_secret}"

    case lookup_token(cache_key) do
      {:ok, token, _expiry} ->
        {:ok, token}

      :not_found ->
        # Fetch new token
        with {:ok, token, expires_in} <- fetch_new_token(config),
             # Calculate expiry time (slightly before actual expiry)
             expiry = :os.system_time(:seconds) + expires_in - 60 do
          # Cache the token
          :ets.insert(@table_name, {cache_key, token, expiry})
          {:ok, token}
        end
    end
  end

  @doc """
  Invalidates a cached token for a specific configuration.
  Useful when a token is rejected by the API.

  ## Parameters

  - config: M-Pesa configuration for the clinic
  """
  def invalidate_token(config) do
    # Initialize ETS table if not exists
    ensure_table_exists()

    # Generate cache key based on credentials
    cache_key = "#{config.consumer_key}:#{config.consumer_secret}"

    # Delete the token from cache
    :ets.delete(@table_name, cache_key)

    :ok
  end

  # Private functions

  defp ensure_table_exists do
    if :ets.whereis(@table_name) == :undefined do
      :ets.new(@table_name, [:named_table, :set, :public])
    end
  end

  defp lookup_token(cache_key) do
    case :ets.lookup(@table_name, cache_key) do
      [{^cache_key, token, expiry}] ->
        if expiry > :os.system_time(:seconds) do
          {:ok, token, expiry}
        else
          :not_found
        end

      [] ->
        :not_found
    end
  end

  defp fetch_new_token(config) do
    url = if config.environment == "production", do: @prod_auth_url, else: @sandbox_auth_url

    auth_header = "Basic " <> Base.encode64("#{config.consumer_key}:#{config.consumer_secret}")

    headers = [
      {"Authorization", auth_header},
      {"Content-Type", "application/json"}
    ]

    Logger.debug("Fetching new M-Pesa access token")

    case HTTPoison.get(url, headers) do
      {:ok, response} when is_map(response) and response.status_code == 200 ->
        case Jason.decode(response.body) do
          {:ok, %{"access_token" => token, "expires_in" => expires_in}} ->
            Logger.debug("Successfully obtained M-Pesa access token")
            {:ok, token, expires_in}

          {:ok, decoded} ->
            Logger.error("Invalid token response format: #{inspect(decoded)}")
            {:error, :invalid_token_response}

          {:error, reason} ->
            Logger.error("Failed to decode token response: #{inspect(reason)}")
            {:error, :invalid_token_response}
        end

      {:ok, response} when is_map(response) ->
        Logger.error("Failed to obtain token: #{response.status_code} - #{response.body}")
        {:error, %{status_code: response.status_code, body: response.body}}

      {:error, error} ->
        Logger.error("HTTP request failed: #{inspect(error)}")
        {:error, error}
    end
  end
end
