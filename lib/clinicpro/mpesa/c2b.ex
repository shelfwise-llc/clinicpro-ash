defmodule Clinicpro.MPesa.C2B do
  @moduledoc """
  Handles M-Pesa Customer-to-Business (C2B) operations with multi-tenant support.
  This module manages C2B URL registration and payment handling for the Safaricom Daraja API,
  ensuring proper isolation between clinics.
  """

  require Logger
  alias Clinicpro.MPesa.{Auth, Config}

  @doc """
  Registers C2B URLs for a specific clinic.

  ## Parameters

  - `_clinic_id` - The ID of the clinic to register URLs for

  ## Returns

  - `{:ok, response}` - If the registration was successful
  - `{:error, reason}` - If the registration failed
  """
  def register_urls(_clinic_id) do
    # Get the clinic's M-Pesa configuration
    config = Config.get_config(_clinic_id)

    # Get access token
    with {:ok, access_token} <- Auth.get_access_token(_clinic_id) do
      # Build the request payload
      payload = %{
        ShortCode: config.shortcode,
        ResponseType: "Completed",
        ConfirmationURL: config.confirmation_url,
        ValidationURL: config.validation_url
      }

      # Build headers
      headers = [
        {"Authorization", "Bearer #{access_token}"},
        {"Content-Type", "application/json"}
      ]

      # Make the request
      url = "#{config.base_url}/mpesa/c2b/v1/registerurl"

      case HTTPoison.post(url, Jason.encode!(payload), headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          # Parse the response
          case Jason.decode(body) do
            {:ok, %{"ResponseCode" => "0", "ResponseDescription" => description}} ->
              Logger.info("C2B URLs registered successfully for clinic #{_clinic_id}: #{description}")
              {:ok, %{description: description}}

            {:ok, %{"errorCode" => error_code, "errorMessage" => error_message}} ->
              Logger.error("C2B URL registration failed for clinic #{_clinic_id}: #{error_code} - #{error_message}")
              {:error, %{code: error_code, message: error_message}}

            {:ok, response} ->
              Logger.error("Unexpected C2B URL registration response for clinic #{_clinic_id}: #{inspect(response)}")
              {:error, :unexpected_response}

            {:error, _} = error ->
              Logger.error("Failed to parse C2B URL registration response for clinic #{_clinic_id}: #{inspect(error)}")
              {:error, :invalid_response}
          end

        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          Logger.error("C2B URL registration failed for clinic #{_clinic_id} with status #{status_code}: #{body}")
          {:error, :request_failed}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("C2B URL registration failed for clinic #{_clinic_id}: #{inspect(reason)}")
          {:error, :request_failed}
      end
    end
  end

  @doc """
  Simulates a C2B payment (only available in sandbox environment).

  ## Parameters

  - `phone_number` - The phone number making the payment
  - `amount` - The amount to pay
  - `reference` - The reference for the _transaction
  - `_clinic_id` - The ID of the clinic receiving the payment

  ## Returns

  - `{:ok, response}` - If the simulation was successful
  - `{:error, reason}` - If the simulation failed
  """
  def simulate_payment(phone_number, amount, reference, _clinic_id) do
    # Get the clinic's M-Pesa configuration
    config = Config.get_config(_clinic_id)

    # Check if we're in sandbox mode
    if config.environment != "sandbox" do
      Logger.error("C2B simulation is only available in sandbox environment for clinic #{_clinic_id}")
      {:error, :simulation_only_in_sandbox}
    else
      # Format the phone number
      formatted_phone = format_phone_number(phone_number)

      # Get access token
      with {:ok, access_token} <- Auth.get_access_token(_clinic_id) do
        # Build the request payload
        payload = %{
          ShortCode: config.shortcode,
          CommandID: "CustomerPayBillOnline",
          Amount: amount,
          Msisdn: formatted_phone,
          BillRefNumber: reference
        }

        # Build headers
        headers = [
          {"Authorization", "Bearer #{access_token}"},
          {"Content-Type", "application/json"}
        ]

        # Make the request
        url = "#{config.base_url}/mpesa/c2b/v1/simulate"

        case HTTPoison.post(url, Jason.encode!(payload), headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            # Parse the response
            case Jason.decode(body) do
              {:ok, %{"ResponseCode" => "0", "ResponseDescription" => description}} ->
                Logger.info("C2B payment simulation successful for clinic #{_clinic_id}: #{description}")
                {:ok, %{description: description}}

              {:ok, %{"errorCode" => error_code, "errorMessage" => error_message}} ->
                Logger.error("C2B payment simulation failed for clinic #{_clinic_id}: #{error_code} - #{error_message}")
                {:error, %{code: error_code, message: error_message}}

              {:ok, response} ->
                Logger.error("Unexpected C2B payment simulation response for clinic #{_clinic_id}: #{inspect(response)}")
                {:error, :unexpected_response}

              {:error, _} = error ->
                Logger.error("Failed to parse C2B payment simulation response for clinic #{_clinic_id}: #{inspect(error)}")
                {:error, :invalid_response}
            end

          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            Logger.error("C2B payment simulation failed for clinic #{_clinic_id} with status #{status_code}: #{body}")
            {:error, :request_failed}

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("C2B payment simulation failed for clinic #{_clinic_id}: #{inspect(reason)}")
            {:error, :request_failed}
        end
      end
    end
  end

  @doc """
  Processes a C2B validation request.

  ## Parameters

  - `params` - The validation request parameters
  - `_clinic_id` - The ID of the clinic receiving the payment

  ## Returns

  - `{:ok, response}` - If the validation was successful
  - `{:error, reason}` - If the validation failed
  """
  def process_validation(params, _clinic_id) do
    # Log the validation request
    Logger.info("Processing C2B validation request for clinic #{_clinic_id}: #{inspect(params)}")

    # Here you would implement your validation logic
    # For example, check if the account number exists, etc.
    # For now, we'll just return a success response

    {:ok, %{
      ResultCode: 0,
      ResultDesc: "Accepted"
    }}
  end

  @doc """
  Processes a C2B confirmation request.

  ## Parameters

  - `params` - The confirmation request parameters
  - `_clinic_id` - The ID of the clinic receiving the payment

  ## Returns

  - `{:ok, response}` - If the confirmation was processed successfully
  - `{:error, reason}` - If the confirmation processing failed
  """
  def process_confirmation(params, _clinic_id) do
    # Log the confirmation request
    Logger.info("Processing C2B confirmation request for clinic #{_clinic_id}: #{inspect(params)}")

    # Extract relevant information from the params
    _transaction_data = %{
      transaction_id: params["TransID"],
      transaction_time: params["TransTime"],
      transaction_amount: params["TransAmount"],
      business_shortcode: params["BusinessShortCode"],
      bill_ref_number: params["BillRefNumber"],
      invoice_number: params["InvoiceNumber"],
      org_account_balance: params["OrgAccountBalance"],
      third_party_trans_id: params["ThirdPartyTransID"],
      phone_number: params["MSISDN"],
      first_name: params["FirstName"],
      middle_name: params["MiddleName"],
      last_name: params["LastName"]
    }

    # Here you would implement your confirmation processing logic
    # For example, update the _transaction status, notify the user, etc.
    # This might involve calling other modules like Transaction or PaymentProcessor

    # For now, we'll just return a success response
    {:ok, %{
      ResultCode: 0,
      ResultDesc: "Confirmation received successfully"
    }}
  end

  # Private functions

  defp format_phone_number(phone_number) do
    # Remove any non-digit characters
    digits = String.replace(phone_number, ~r/\D/, "")

    # Handle different formats
    cond do
      # If it starts with 254, keep it as is
      String.starts_with?(digits, "254") ->
        digits

      # If it starts with 0, replace with 254
      String.starts_with?(digits, "0") ->
        "254" <> String.slice(digits, 1..-1)

      # If it's 9 digits, assume it's missing the 254 prefix
      String.length(digits) == 9 ->
        "254" <> digits

      # Otherwise, return as is
      true ->
        digits
    end
  end
end
