defmodule Clinicpro.MPesaCoreTest do
  @moduledoc """
  Core test for the Clinicpro.MPesa module functionality.
  This module tests the M-Pesa implementation without relying on database or web components.
  """

  # Import the M-Pesa module and its submodules
  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.Config
  alias Clinicpro.MPesa.STKPush
  alias Clinicpro.MPesa.C2B
  alias Clinicpro.MPesa.Auth

  @doc """
  Run all M-Pesa core tests
  """
  def run_all_tests do
    IO.puts("=== ClinicPro M-Pesa Core Tests ===")
    IO.puts("Testing the core M-Pesa functionality")
    IO.puts("All tests run in sandbox mode - no real transactions")
    IO.puts("===========================================\n")

    # Create a test configuration
    config = create_test_config()

    # Run STK Push test
    run_stk_push_test(config)

    IO.puts("\n" <> String.duplicate("-", 60) <> "\n")

    # Run C2B URL registration test
    run_c2b_registration_test(config)
  end

  @doc """
  Test the STK Push functionality directly using the STKPush module
  """
  def run_stk_push_test(config) do
    IO.puts("TESTING STK PUSH FUNCTIONALITY")
    IO.puts("-----------------------------")

    # Get test phone number from environment or use default
    phone = format_phone(System.get_env("MPESA_TEST_PHONE") || "0713701723")

    # Create a unique reference for this test
    reference = "TEST-#{:rand.uniform(999_999)}"

    # Use a small amount for testing
    amount = 1

    # Description for the transaction
    description = "M-Pesa Core Test"

    # Display test parameters
    IO.puts("Phone number: #{phone}")
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Environment: #{config.environment}")
    IO.puts("Shortcode: #{config.shortcode}")

    IO.puts("\nInitiating STK Push request...")

    # Call the STKPush module directly
    case STKPush.request(config, phone, amount, reference, description) do
      {:ok, response} ->
        IO.puts("\n✅ STK Push initiated successfully!")
        IO.puts("Checkout Request ID: #{response["CheckoutRequestID"]}")
        IO.puts("Merchant Request ID: #{response["MerchantRequestID"]}")
        IO.puts("Response Code: #{response["ResponseCode"]}")
        IO.puts("Response Description: #{response["ResponseDescription"]}")
        IO.puts("\nPlease check your phone #{phone} for the STK Push prompt")
        IO.puts("Note: In sandbox mode, no actual prompt will be sent to the phone.")

      {:error, reason} ->
        IO.puts("\n❌ Failed to initiate STK Push: #{inspect(reason)}")
    end
  end

  @doc """
  Test the C2B URL registration functionality directly using the C2B module
  """
  def run_c2b_registration_test(config) do
    IO.puts("TESTING C2B URL REGISTRATION")
    IO.puts("---------------------------")

    # Display test parameters
    IO.puts("Shortcode: #{config.c2b_shortcode}")
    IO.puts("Validation URL: #{config.c2b_validation_url}")
    IO.puts("Confirmation URL: #{config.c2b_confirmation_url}")
    IO.puts("Environment: #{config.environment}")

    IO.puts("\nRegistering C2B URLs...")

    # Call the C2B module directly
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
  Create a test configuration for M-Pesa
  """
  def create_test_config do
    # Use environment variables if available, otherwise use defaults
    %Config{
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
      environment: "sandbox"
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
      "254" <> String.slice(digits, 1..-1)
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
Clinicpro.MPesaCoreTest.run_all_tests()
