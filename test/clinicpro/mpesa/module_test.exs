defmodule Clinicpro.MPesaModuleTest do
  @moduledoc """
  Module test for the M-Pesa integration.
  This module tests the actual M-Pesa modules by mocking the database components.
  """

  # Import the actual M-Pesa modules
  alias Clinicpro.MPesa.Auth
  alias Clinicpro.MPesa.STKPush
  alias Clinicpro.MPesa.C2B

  # Define a mock Config struct that matches the schema in Clinicpro.MPesa.Config
  defmodule MockConfig do
    defstruct [
      :clinic_id,
      :consumer_key,
      :consumer_secret,
      :passkey,
      :shortcode,
      :c2b_shortcode,
      :environment,
      :stk_callback_url,
      :c2b_validation_url,
      :c2b_confirmation_url,
      :active
    ]
  end

  @doc """
  Run all M-Pesa module tests
  """
  def run_all_tests do
    IO.puts("=== ClinicPro M-Pesa Module Tests ===")
    IO.puts("Testing the actual M-Pesa modules with mocked database")
    IO.puts("All tests run in sandbox mode - no real transactions")
    IO.puts("===========================================\n")

    # Create a mock configuration
    config = create_mock_config()

    # Run authentication test
    test_auth(config)

    IO.puts("\n" <> String.duplicate("-", 50) <> "\n")

    # Run STK Push test
    test_stk_push(config)

    IO.puts("\n" <> String.duplicate("-", 50) <> "\n")

    # Run C2B URL registration test
    test_c2b_url_registration(config)
  end

  @doc """
  Test the authentication functionality
  """
  def test_auth(config) do
    IO.puts("TESTING M-PESA AUTHENTICATION")
    IO.puts("--------------------------")

    IO.puts("Consumer Key: #{String.slice(config.consumer_key, 0, 3)}***")
    IO.puts("Consumer Secret: #{String.slice(config.consumer_secret, 0, 3)}***")
    IO.puts("Environment: #{config.environment}")

    IO.puts("\nGetting authentication token...")

    # Call the actual Auth module
    case Auth.get_token(config) do
      {:ok, token, _expiry} ->
        IO.puts("\n✅ Authentication successful!")
        IO.puts("Token: #{String.slice(token, 0, 10)}***")

      {:error, reason} ->
        IO.puts("\n❌ Authentication failed: #{inspect(reason)}")
    end
  end

  @doc """
  Test the STK Push functionality
  """
  def test_stk_push(config) do
    IO.puts("TESTING STK PUSH")
    IO.puts("---------------")

    # Get test phone number from environment or use default
    phone = format_phone(System.get_env("MPESA_TEST_PHONE") || "0713701723")

    # Use a small amount for testing
    amount = 1

    # Create a unique reference for this test
    reference = "TEST-#{:rand.uniform(999_999)}"

    # Description for the transaction
    description = "M-Pesa Module Test"

    # Display test parameters
    IO.puts("Phone: #{phone}")
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Description: #{description}")
    IO.puts("Environment: #{config.environment}")
    IO.puts("Shortcode: #{config.shortcode}")
    IO.puts("Callback URL: #{config.stk_callback_url}")

    IO.puts("\nInitiating STK Push request...")

    # Call the actual STKPush module
    case STKPush.request(config, phone, amount, reference, description) do
      {:ok, response} ->
        IO.puts("\n✅ STK Push initiated successfully!")
        IO.puts("Checkout Request ID: #{response["CheckoutRequestID"]}")
        IO.puts("Merchant Request ID: #{response["MerchantRequestID"]}")
        IO.puts("Response Code: #{response["ResponseCode"]}")
        IO.puts("Response Description: #{response["ResponseDescription"]}")
        IO.puts("\nPlease check your phone #{phone} for the STK Push prompt")
        IO.puts("Note: In sandbox mode, no actual prompt will be sent to the phone")

      {:error, reason} ->
        IO.puts("\n❌ Failed to initiate STK Push: #{inspect(reason)}")
    end
  end

  @doc """
  Test the C2B URL registration functionality
  """
  def test_c2b_url_registration(config) do
    IO.puts("TESTING C2B URL REGISTRATION")
    IO.puts("--------------------------")

    # Display test parameters
    IO.puts("Shortcode: #{config.c2b_shortcode}")
    IO.puts("Validation URL: #{config.c2b_validation_url}")
    IO.puts("Confirmation URL: #{config.c2b_confirmation_url}")
    IO.puts("Environment: #{config.environment}")

    IO.puts("\nRegistering C2B URLs...")

    # Call the actual C2B module
    case C2B.register_urls(config) do
      {:ok, response} ->
        IO.puts("\n✅ C2B URLs registered successfully!")
        IO.puts("Originator Conversation ID: #{response["OriginatorConversationID"]}")
        IO.puts("Response Code: #{response["ResponseCode"]}")
        IO.puts("Response Description: #{response["ResponseDescription"]}")

      {:error, reason} ->
        IO.puts("\n❌ Failed to register C2B URLs: #{inspect(reason)}")
    end
  end

  @doc """
  Create a mock configuration for M-Pesa
  """
  def create_mock_config do
    # Use environment variables if available, otherwise use defaults
    %MockConfig{
      clinic_id: "test_clinic",
      consumer_key: System.get_env("MPESA_CONSUMER_KEY") || "test_consumer_key",
      consumer_secret: System.get_env("MPESA_CONSUMER_SECRET") || "test_consumer_secret",
      passkey: System.get_env("MPESA_PASSKEY") || "test_passkey",
      shortcode: System.get_env("MPESA_SHORTCODE") || "174379",
      c2b_shortcode: System.get_env("MPESA_C2B_SHORTCODE") || "174379",
      stk_callback_url:
        System.get_env("MPESA_STK_CALLBACK_URL") || "https://example.com/mpesa/stk/callback",
      c2b_validation_url:
        System.get_env("MPESA_C2B_VALIDATION_URL") || "https://example.com/mpesa/c2b/validation",
      c2b_confirmation_url:
        System.get_env("MPESA_C2B_CONFIRMATION_URL") ||
          "https://example.com/mpesa/c2b/confirmation",
      environment: "sandbox",
      active: true
    }
  end

  @doc """
  Format phone number to the required format (254XXXXXXXXX)
  """
  def format_phone(phone) do
    # Remove any non-digit characters
    digits = String.replace(phone, ~r/\D/, "")

    # If the number starts with 0, replace it with 254
    if String.starts_with?(digits, "0") do
      "254" <> String.slice(digits, 1..-1//1)
    else
      # If it already starts with 254, return as is
      if String.starts_with?(digits, "254") do
        digits
      else
        # Otherwise, assume it's a 9-digit number and add 254
        "254" <> digits
      end
    end
  end
end

# Run the tests when this script is executed directly
Clinicpro.MPesaModuleTest.run_all_tests()
