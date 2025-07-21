defmodule Clinicpro.MPesa.Helpers do
  @moduledoc """
  Helper functions for M-Pesa integration.

  Provides utility functions for:
  1. Phone number validation and normalization
  2. HTTP request handling
  3. Timestamp generation
  4. Error handling
  """

  require Logger

  @doc """
  Validates and normalizes a phone number to the format required by M-Pesa.

  ## Examples

      iex> Clinicpro.MPesa.Helpers.validate_phone_number("0712345678")
      {:ok, "254712345678"}

      iex> Clinicpro.MPesa.Helpers.validate_phone_number("+254712345678")
      {:ok, "254712345678"}

      iex> Clinicpro.MPesa.Helpers.validate_phone_number("712345678")
      {:ok, "254712345678"}

      iex> Clinicpro.MPesa.Helpers.validate_phone_number("invalid")
      {:error, :invalid_phone_number}
  """
  def validate_phone_number(phone) when is_binary(phone) do
    # Remove any non-digit characters
    digits_only = String.replace(phone, ~r/\D/, "")

    cond do
      # If starts with 254, assume it's already in the correct format
      String.starts_with?(digits_only, "254") and String.length(digits_only) == 12 ->
        {:ok, digits_only}

      # If starts with 0, replace with 254
      String.starts_with?(digits_only, "0") and String.length(digits_only) == 10 ->
        {:ok, "254" <> String.slice(digits_only, 1..-1)}

      # If 9 digits, assume it's missing the leading 0, add 254
      String.length(digits_only) == 9 ->
        {:ok, "254" <> digits_only}

      # Invalid format
      true ->
        {:error, :invalid_phone_number}
    end
  end

  def validate_phone_number(_), do: {:error, :invalid_phone_number}

  @doc """
  Makes an HTTP request to the M-Pesa API.

  ## Parameters

  - url: The URL to make the request to
  - payload: The request payload
  - token: The access token for authentication

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def make_request(url, payload, token) do
    headers = [
      {"Authorization", "Bearer " <> token},
      {"Content-Type", "application/json"}
    ]

    # Log request (without sensitive data)
    sanitized_payload = sanitize_payload(payload)
    Logger.debug("M-Pesa API request to #{url}: #{inspect(sanitized_payload)}")

    case HTTPoison.post(url, Jason.encode!(payload), headers) do
      {:ok, response} when is_map(response) and response.status_code in 200..299 ->
        case Jason.decode(response.body) do
          {:ok, decoded} ->
            # Log response (without sensitive data)
            sanitized_response = sanitize_response(decoded)
            Logger.debug("M-Pesa API response: #{inspect(sanitized_response)}")

            # Check for M-Pesa API errors
            if Map.has_key?(decoded, "errorCode") do
              {:error,
               %{error_code: decoded["errorCode"], error_message: decoded["errorMessage"]}}
            else
              {:ok, decoded}
            end

          {:error, _} ->
            Logger.error("Failed to decode M-Pesa API response: #{response.body}")
            {:error, :invalid_response_format}
        end

      {:ok, response} when is_map(response) ->
        Logger.error("M-Pesa API error: #{response.status_code} - #{response.body}")
        {:error, %{status_code: response.status_code, body: response.body}}

      {:error, error} ->
        Logger.error("HTTP request failed: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Generates a timestamp in the format required by M-Pesa (YYYYMMDDHHmmss).

  ## Returns

  - {:ok, timestamp} on success
  """
  def get_timestamp do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.to_string()
      |> String.replace(~r/[^\d]/, "")
      |> String.slice(0, 14)

    {:ok, timestamp}
  end

  # Private functions

  # Remove sensitive data from logs
  defp sanitize_payload(payload) do
    case payload do
      %{"Password" => _} = p ->
        Map.put(p, "Password", "[REDACTED]")

      other ->
        other
    end
  end

  # Remove sensitive data from logs
  defp sanitize_response(response) do
    # Implement based on response structure
    response
  end
end
