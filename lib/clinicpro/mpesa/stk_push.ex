defmodule Clinicpro.MPesa.STKPush do
  @moduledoc """
  Handles STK Push requests to M-Pesa.

  This module is responsible for:
  1. Initiating STK Push requests
  2. Querying STK Push transaction status
  3. Handling request formatting and validation
  """

  require Logger
  alias Clinicpro.MPesa.{Auth, Helpers}

  @sandbox_url "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
  @prod_url "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
  @sandbox_query_url "https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query"
  @prod_query_url "https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query"

  @doc """
  Sends an STK Push request to M-Pesa.

  ## Parameters

  - config: M-Pesa configuration for the clinic
  - phone: Customer's phone number
  - amount: Amount to be paid
  - reference: Your reference for this transaction
  - description: Transaction description

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def request(config, phone, amount, reference, description) do
    url = if config.environment == "production", do: @prod_url, else: @sandbox_url

    with {:ok, normalized_phone} <- Helpers.validate_phone_number(phone),
         {:ok, token} <- Auth.get_access_token(config),
         {:ok, timestamp} <- Helpers.get_timestamp(),
         password = generate_password(config, timestamp),
         payload =
           build_payload(
             config,
             normalized_phone,
             amount,
             reference,
             description,
             timestamp,
             password
           ),
         {:ok, response} <- Helpers.make_request(url, payload, token) do
      {:ok, response}
    else
      {:error, :invalid_phone_number} ->
        Logger.error("Invalid phone number format: #{phone}")
        {:error, :invalid_phone_number}

      {:error, reason} ->
        Logger.error("STK Push request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Queries the status of an STK Push transaction.

  ## Parameters

  - config: M-Pesa configuration for the clinic
  - checkout_request_id: The CheckoutRequestID returned by the STK push request

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def query_status(config, checkout_request_id) do
    url = if config.environment == "production", do: @prod_query_url, else: @sandbox_query_url

    with {:ok, token} <- Auth.get_access_token(config),
         {:ok, timestamp} <- Helpers.get_timestamp(),
         password = generate_password(config, timestamp),
         payload = build_query_payload(config, checkout_request_id, timestamp, password),
         {:ok, response} <- Helpers.make_request(url, payload, token) do
      {:ok, response}
    else
      {:error, reason} ->
        Logger.error("STK Push status query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp generate_password(config, timestamp) do
    data = "#{config.shortcode}#{config.passkey}#{timestamp}"
    Base.encode64(data)
  end

  defp build_payload(config, phone, amount, reference, description, timestamp, password) do
    %{
      "BusinessShortCode" => config.shortcode,
      "Password" => password,
      "Timestamp" => timestamp,
      "TransactionType" => "CustomerPayBillOnline",
      "Amount" => amount,
      "PartyA" => phone,
      "PartyB" => config.shortcode,
      "PhoneNumber" => phone,
      "CallBackURL" => config.stk_callback_url,
      "AccountReference" => reference,
      "TransactionDesc" => description
    }
  end

  defp build_query_payload(config, checkout_request_id, timestamp, password) do
    %{
      "BusinessShortCode" => config.shortcode,
      "Password" => password,
      "Timestamp" => timestamp,
      "CheckoutRequestID" => checkout_request_id
    }
  end
end
