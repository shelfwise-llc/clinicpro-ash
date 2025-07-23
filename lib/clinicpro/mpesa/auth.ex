defmodule Clinicpro.MPesa.Auth do
  @moduledoc """
  Handles M-Pesa authentication with multi-tenant support.
  This module manages authentication with the Safaricom Daraja API,
  ensuring proper isolation between clinics.
  """

  require Logger
  alias Clinicpro.MPesa.Config

  @doc """
  Generates an access token for M-Pesa API calls.

  ## Parameters

  - `clinic_id` - The ID of the clinic to generate an access token for

  ## Returns

  - `{:ok, %{access_token: token, expires_in: seconds}}` - If the token was generated successfully
  - `{:error, reason}` - If the token generation failed
  """
  def generate_access_token(clinic_id) do
    # Get the clinic's M-Pesa configuration
    config = Config.get_config(clinic_id)

    # Build the authorization header
    auth_string = Base.encode64("#{config.consumer_key}:#{config.consumer_secret}")
    headers = [
      {"Authorization", "Basic #{auth_string}"},
      {"Content-Type", "application/json"}
    ]

    # Make the request to the M-Pesa API
    url = "#{config.base_url}/oauth/v1/generate?grant_type=client_credentials"

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Parse the response
        case Jason.decode(body) do
          {:ok, %{"access_token" => token, "expires_in" => expires_in}} ->
            # Cache the token (optional)
            cache_token(clinic_id, token, expires_in)

            {:ok, %{access_token: token, expires_in: expires_in}}

          {:error, _} = error ->
            Logger.error("Failed to parse M-Pesa access token response: #{inspect(error)}")
            {:error, :invalid_response}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("M-Pesa access token request failed with status #{status_code}: #{body}")
        {:error, :request_failed}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("M-Pesa access token request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end

  @doc """
  Gets a cached access token for a clinic if available, otherwise generates a new one.

  ## Parameters

  - `clinic_id` - The ID of the clinic to get an access token for

  ## Returns

  - `{:ok, token}` - If a valid token was found or generated
  - `{:error, reason}` - If the token retrieval failed
  """
  def get_access_token(clinic_id) do
    case get_cached_token(clinic_id) do
      {:ok, token} ->
        {:ok, token}

      {:error, _} ->
        # No valid cached token, generate a new one
        case generate_access_token(clinic_id) do
          {:ok, %{access_token: token}} -> {:ok, token}
          error -> error
        end
    end
  end

  @doc """
  Generates a password for STK Push requests.

  ## Parameters

  - `shortcode` - The M-Pesa shortcode
  - `passkey` - The M-Pesa passkey
  - `timestamp` - The timestamp to use in the password

  ## Returns

  - The generated password
  """
  def generate_password(shortcode, passkey, timestamp) do
    Base.encode64("#{shortcode}#{passkey}#{timestamp}")
  end

  @doc """
  Generates a timestamp for M-Pesa API calls in the format YYYYMMDDHHmmss.

  ## Returns

  - The generated timestamp
  """
  def generate_timestamp do
    DateTime.utc_now()
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.replace(~r/[^\d]/, "")
    |> String.slice(0, 14)
  end

  # Private functions

  # These functions implement a simple in-memory cache for access tokens
  # In a production environment, you might want to use a more robust caching solution

  defp cache_token(clinic_id, token, expires_in) do
    # Calculate expiry time (subtract a buffer to ensure we don't use an expired token)
    buffer = 60 # 1 minute buffer
    expiry = :os.system_time(:second) + expires_in - buffer

    # Store the token in the process dictionary
    # In a real application, you would use a proper cache like ETS or Redis
    Process.put({:mpesa_token, clinic_id}, {token, expiry})

    :ok
  end

  defp get_cached_token(clinic_id) do
    case Process.get({:mpesa_token, clinic_id}) do
      nil ->
        {:error, :no_cached_token}

      {token, expiry} ->
        # Check if the token is still valid
        if :os.system_time(:second) < expiry do
          {:ok, token}
        else
          # Token has expired
          Process.delete({:mpesa_token, clinic_id})
          {:error, :token_expired}
        end
    end
  end
end
