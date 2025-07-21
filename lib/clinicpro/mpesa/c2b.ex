defmodule Clinicpro.MPesa.C2B do
  @moduledoc """
  Handles C2B (Customer to Business) payments for M-Pesa.

  This module is responsible for:
  1. Registering validation and confirmation URLs
  2. Handling C2B payment requests
  3. Processing C2B callbacks
  """

  require Logger
  alias Clinicpro.MPesa.{Auth, Helpers}

  @sandbox_register_url "https://sandbox.safaricom.co.ke/mpesa/c2b/v1/registerurl"
  @prod_register_url "https://api.safaricom.co.ke/mpesa/c2b/v1/registerurl"
  @sandbox_simulate_url "https://sandbox.safaricom.co.ke/mpesa/c2b/v1/simulate"
  @prod_simulate_url "https://api.safaricom.co.ke/mpesa/c2b/v1/simulate"

  @doc """
  Registers validation and confirmation URLs for C2B payments.

  ## Parameters

  - config: M-Pesa configuration for the clinic

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def register_urls(config) do
    url =
      if config.environment == "production", do: @prod_register_url, else: @sandbox_register_url

    with {:ok, token} <- Auth.get_access_token(config),
         payload = build_register_payload(config),
         {:ok, response} <- Helpers.make_request(url, payload, token) do
      {:ok, response}
    else
      {:error, reason} ->
        Logger.error("Failed to register C2B URLs: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Simulates a C2B payment (only works in sandbox environment).

  ## Parameters

  - config: M-Pesa configuration for the clinic
  - phone: Customer's phone number
  - amount: Amount to be paid
  - reference: Your reference for this transaction

  ## Returns

  - {:ok, response} on success
  - {:error, reason} on failure
  """
  def simulate_payment(config, phone, amount, reference) do
    if config.environment != "sandbox" do
      {:error, :simulation_only_in_sandbox}
    else
      url = @sandbox_simulate_url

      with {:ok, normalized_phone} <- Helpers.validate_phone_number(phone),
           {:ok, token} <- Auth.get_access_token(config),
           payload = build_simulate_payload(config, normalized_phone, amount, reference),
           {:ok, response} <- Helpers.make_request(url, payload, token) do
        {:ok, response}
      else
        {:error, :invalid_phone_number} ->
          Logger.error("Invalid phone number format: #{phone}")
          {:error, :invalid_phone_number}

        {:error, reason} ->
          Logger.error("C2B simulation failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  # Private functions

  defp build_register_payload(config) do
    # Use the c2b_shortcode if available, otherwise use the regular shortcode
    shortcode = config.c2b_shortcode || config.shortcode

    %{
      "ShortCode" => shortcode,
      "ResponseType" => "Completed",
      "ConfirmationURL" => config.c2b_confirmation_url,
      "ValidationURL" => config.c2b_validation_url
    }
  end

  defp build_simulate_payload(config, phone, amount, reference) do
    # Use the c2b_shortcode if available, otherwise use the regular shortcode
    shortcode = config.c2b_shortcode || config.shortcode

    %{
      "ShortCode" => shortcode,
      "CommandID" => "CustomerPayBillOnline",
      "Amount" => amount,
      "Msisdn" => phone,
      "BillRefNumber" => reference
    }
  end
end
