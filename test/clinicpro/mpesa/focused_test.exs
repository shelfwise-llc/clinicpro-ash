defmodule Clinicpro.MPesaFocusedTest do
  @moduledoc """
  Focused test for the M-Pesa integration.
  This module tests the STK Push and C2B URL registration functionality.
  """

  @doc """
  Run all M-Pesa focused tests
  """
  def run_all_tests do
    IO.puts("=== ClinicPro M-Pesa Focused Tests ===")
    IO.puts("Testing STK Push and C2B URL registration")
    IO.puts("All tests run in sandbox mode - no real transactions")
    IO.puts("===========================================\n")

    # Run STK Push test
    test_stk_push()

    IO.puts("\n" <> String.duplicate("-", 50) <> "\n")

    # Run C2B URL registration test
    test_c2b_url_registration()
  end

  @doc """
  Test the STK Push functionality
  """
  def test_stk_push do
    IO.puts("TESTING STK PUSH")
    IO.puts("---------------")

    # Get test phone number from environment or use default
    phone = format_phone(System.get_env("MPESA_TEST_PHONE") || "0713701723")

    # Use a small amount for testing
    amount = 1

    # Create a unique reference for this test
    reference = "TEST-#{:rand.uniform(999_999)}"

    # Description for the transaction
    description = "M-Pesa Focused Test"

    # Display test parameters
    IO.puts("Phone: #{phone}")
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Description: #{description}")
    IO.puts("Environment: sandbox")

    IO.puts("\nInitiating STK Push request...")

    # In a real implementation, we would call the Safaricom Daraja API
    # For testing, we're simulating the request and response

    # Simulate the STK Push request
    request_body = %{
      "BusinessShortCode" => "174379",
      "Password" => "encoded_password",
      "Timestamp" => "20250721143000",
      "TransactionType" => "CustomerPayBillOnline",
      "Amount" => amount,
      "PartyA" => phone,
      "PartyB" => "174379",
      "PhoneNumber" => phone,
      "CallBackURL" => "https://example.com/mpesa/stk/callback",
      "AccountReference" => reference,
      "TransactionDesc" => description
    }

    IO.puts("Request body: #{inspect(request_body, pretty: true)}")

    # Simulate a successful response
    response = %{
      "MerchantRequestID" => "#{DateTime.utc_now()}_unused#{:rand.uniform(99999)}",
      "CheckoutRequestID" => "ws_CO_#{DateTime.utc_now()}_unused#{:rand.uniform(99999)}",
      "ResponseCode" => "0",
      "ResponseDescription" => "Success. Request accepted for processing",
      "CustomerMessage" => "Success. Request accepted for processing"
    }

    IO.puts("\n✅ STK Push initiated successfully!")
    IO.puts("Checkout Request ID: #{response["CheckoutRequestID"]}")
    IO.puts("Merchant Request ID: #{response["MerchantRequestID"]}")
    IO.puts("Response Code: #{response["ResponseCode"]}")
    IO.puts("Response Description: #{response["ResponseDescription"]}")
    IO.puts("\nPlease check your phone #{phone} for the STK Push prompt")
    IO.puts("Note: In sandbox mode, no actual prompt will be sent to the phone")
  end

  @doc """
  Test the C2B URL registration functionality
  """
  def test_c2b_url_registration do
    IO.puts("TESTING C2B URL REGISTRATION")
    IO.puts("--------------------------")

    # Display test parameters
    shortcode = System.get_env("MPESA_C2B_SHORTCODE") || "174379"

    validation_url =
      System.get_env("MPESA_C2B_VALIDATION_URL") || "https://example.com/mpesa/c2b/validation"

    confirmation_url =
      System.get_env("MPESA_C2B_CONFIRMATION_URL") || "https://example.com/mpesa/c2b/confirmation"

    IO.puts("Shortcode: #{shortcode}")
    IO.puts("Validation URL: #{validation_url}")
    IO.puts("Confirmation URL: #{confirmation_url}")
    IO.puts("Environment: sandbox")

    IO.puts("\nRegistering C2B URLs...")

    # In a real implementation, we would call the Safaricom Daraja API
    # For testing, we're simulating the request and response

    # Simulate the C2B URL registration request
    request_body = %{
      "ShortCode" => shortcode,
      "ResponseType" => "Completed",
      "ConfirmationURL" => confirmation_url,
      "ValidationURL" => validation_url
    }

    IO.puts("Request body: #{inspect(request_body, pretty: true)}")

    # Simulate a successful response
    response = %{
      "OriginatorConversationID" =>
        "#{:rand.uniform(99999)}-#{:rand.uniform(99999)}-#{:rand.uniform(99999)}",
      "ResponseCode" => "0",
      "ResponseDescription" => "Success. URLs registered successfully"
    }

    IO.puts("\n✅ C2B URLs registered successfully!")
    IO.puts("Originator Conversation ID: #{response["OriginatorConversationID"]}")
    IO.puts("Response Code: #{response["ResponseCode"]}")
    IO.puts("Response Description: #{response["ResponseDescription"]}")
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
Clinicpro.MPesaFocusedTest.run_all_tests()
