defmodule Clinicpro.MPesa.STKPush do
  @moduledoc """
  Handles M-Pesa STK Push requests with multi-tenant support.
  This module implements the STKPushBehaviour for production use.
  """

  @behaviour Clinicpro.MPesa.STKPushBehaviour

  alias Clinicpro.MPesa.Auth
  alias Clinicpro.MPesa.Config
  alias Clinicpro.MPesa.Helpers

  @doc """
  Initiates an STK Push request to the M-Pesa API.

  ## Parameters

  - `phone_number` - The phone number to send the STK push to
  - `amount` - The amount to charge
  - `reference` - The reference number for the _transaction
  - `_clinic_id` - The ID of the clinic (for multi-tenant support)

  ## Returns

  - `{:ok, response}` - If the request was successful
  - `{:error, reason}` - If the request failed
  """
  @impl true
  def request(phone_number, amount, reference, _clinic_id) do
    # Get clinic-specific configuration
    config = Config.get_config(_clinic_id)

    # Format the phone number if needed
    phone_number = Helpers.format_phone_number(phone_number)

    # Format the amount to integer (M-Pesa requires amount as integer)
    amount = Helpers.format_amount(amount)

    # Get the timestamp for the request
    timestamp = Helpers.get_timestamp()

    # Generate the password
    password = Helpers.generate_password(config.shortcode, config.passkey, timestamp)

    # Get the access token
    with {:ok, token} <- Auth.get_access_token(_clinic_id),
         {:ok, response} <- do_request(token, phone_number, amount, reference, timestamp, password, config) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp do_request(token, phone_number, amount, reference, timestamp, password, config) do
    # Prepare the request body
    body = %{
      "BusinessShortCode" => config.shortcode,
      "Password" => password,
      "Timestamp" => timestamp,
      "TransactionType" => "CustomerPayBillOnline",
      "Amount" => amount,
      "PartyA" => phone_number,
      "PartyB" => config.shortcode,
      "PhoneNumber" => phone_number,
      "CallBackURL" => "#{config.callback_url}/api/mpesa/callbacks/#{config._clinic_id}/stk_push",
      "AccountReference" => reference,
      "TransactionDesc" => "Payment for #{reference}"
    }

    # Prepare the headers
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    # Make the request
    url = "#{config.base_url}/mpesa/stkpush/v1/processrequest"

    case HTTPoison.post(url, Jason.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:error, "Failed to decode response"}
        end

      {:ok, %HTTPoison.Response{body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"errorMessage" => error}} -> {:error, error}
          {:ok, decoded} -> {:error, "Unexpected response: #{inspect(decoded)}"}
          {:error, _} -> {:error, "Failed to decode error response"}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end
end
