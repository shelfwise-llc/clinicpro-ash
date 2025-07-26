defmodule Clinicpro.MPesaTest do
  @moduledoc """
  Test script for verifying M-Pesa integration with the provided credentials.

  This module provides functions to test various aspects of the M-Pesa integration,
  including authentication, STK Push, and transaction handling.
  """

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.Config
  alias Clinicpro.MPesa.Transaction

  @doc """
  Main test function that runs all tests in sequence.
  """
  def run_tests do
    IO.puts("Starting M-Pesa integration tests...")

    # Test clinic ID for testing
    clinic_id = 1

    # Step 1: Create test configuration
    IO.puts("\n1. Creating test configuration...")
    {:ok, config} = create_test_config(clinic_id)
    IO.puts("✓ Test configuration created with ID: #{config.id}")

    # Step 2: Test authentication
    IO.puts("\n2. Testing authentication...")

    case test_authentication(clinic_id) do
      {:ok, token} ->
        IO.puts("✓ Authentication successful. Token received.")

        # Step 3: Test STK Push
        IO.puts("\n3. Testing STK Push...")
        test_stk_push(clinic_id)

        # Step 4: Test transaction listing
        IO.puts("\n4. Testing transaction listing...")
        test_transaction_listing(clinic_id)

      {:error, reason} ->
        IO.puts("✗ Authentication failed: #{inspect(reason)}")
    end

    IO.puts("\nM-Pesa integration tests completed.")
  end

  @doc """
  Creates a test configuration using the credentials from .env-local.
  """
  def create_test_config(clinic_id) do
    config_params = %{
      clinic_id: clinic_id,
      consumer_key: "GBOmMgVvYQoOZE1qZQds4dIGCSFhGbSuPX3gQR5egDROR069",
      consumer_secret: "pSwhuZTpcKWxUNOzHPLkPiGKpjAKOaU67VVXe5t2VAQXuuwH2c4UGlseElGvEVpF",
      # Default sandbox passkey
      passkey: "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
      # Default sandbox shortcode
      shortcode: "174379",
      environment: "sandbox",
      base_url: "https://sandbox.safaricom.co.ke",
      callback_url: "https://example.com/mpesa/callback",
      validation_url: "https://example.com/mpesa/validate",
      confirmation_url: "https://example.com/mpesa/confirm",
      active: true
    }

    # Delete any existing configs for this clinic
    existing_configs = Config.list_configs(clinic_id)

    Enum.each(existing_configs, fn config ->
      Config.deactivate(config.id)
    end)

    # Create new config
    Config.create(config_params)
  end

  @doc """
  Tests authentication with the Safaricom API.
  """
  def test_authentication(clinic_id) do
    case MPesa.Auth.generate_token(clinic_id) do
      {:ok, token} ->
        IO.puts("Token: #{String.slice(token, 0, 20)}...")
        {:ok, token}

      {:error, reason} = error ->
        IO.puts("Authentication failed: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Tests STK Push functionality.
  """
  def test_stk_push(clinic_id) do
    # Test phone number - replace with a valid test number if needed
    phone_number = "254712345678"

    # Test invoice and patient IDs
    invoice_id = "TEST-INV-#{System.os_time(:second)}"
    patient_id = "TEST-PATIENT-#{System.os_time(:second)}"

    # Test amount
    # Minimum amount for testing
    amount = 1

    IO.puts("Initiating STK Push to #{phone_number} for KES #{amount}...")

    case MPesa.initiate_stk_push(clinic_id, invoice_id, patient_id, phone_number, amount) do
      {:ok, transaction} ->
        IO.puts("✓ STK Push initiated successfully")
        IO.puts("  Transaction ID: #{transaction.id}")
        IO.puts("  Checkout Request ID: #{transaction.checkout_request_id}")
        IO.puts("  Merchant Request ID: #{transaction.merchant_request_id}")

        # Wait for a moment and then check the status
        IO.puts("\nWaiting 10 seconds before checking status...")
        :timer.sleep(10_000)

        case MPesa.query_stk_push_status(clinic_id, transaction.checkout_request_id) do
          {:ok, status} ->
            IO.puts("✓ STK Push status: #{inspect(status)}")

          {:error, reason} ->
            IO.puts("✗ Failed to query STK Push status: #{inspect(reason)}")
        end

      {:error, reason} ->
        IO.puts("✗ STK Push failed: #{inspect(reason)}")
    end
  end

  @doc """
  Tests transaction listing functionality.
  """
  def test_transaction_listing(clinic_id) do
    transactions = Transaction.list_by_clinic(clinic_id)

    IO.puts("Found #{length(transactions)} transactions for clinic #{clinic_id}")

    if length(transactions) > 0 do
      IO.puts("\nLatest transaction:")
      latest = List.first(transactions)
      IO.puts("  ID: #{latest.id}")
      IO.puts("  Invoice ID: #{latest.invoice_id}")
      IO.puts("  Amount: #{latest.amount}")
      IO.puts("  Status: #{latest.status}")
      IO.puts("  Created at: #{latest.inserted_at}")
    end
  end
end

# Run the tests when this script is executed
Clinicpro.MPesaTest.run_tests()
