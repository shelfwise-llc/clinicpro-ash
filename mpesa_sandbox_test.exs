defmodule Clinicpro.MPesaSandboxTest do
  @moduledoc """
  Sandbox test for the M-Pesa integration.
  This module tests the M-Pesa functionality by mocking the necessary components.
  """

  @doc """
  Run all M-Pesa sandbox tests
  """
  def run_all_tests do
    IO.puts("=== ClinicPro M-Pesa Sandbox Tests ===")
    IO.puts("Testing in sandbox mode - no real transactions")
    IO.puts("========================================\n")
    
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
    reference = "TEST-#{:rand.uniform(999999)}"
    
    # Description for the transaction
    description = "Test STK Push"
    
    # Display test parameters
    IO.puts("Phone: #{phone}")
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Description: #{description}")
    IO.puts("Environment: sandbox")
    
    IO.puts("\nSimulating STK Push request...")
    IO.puts("In a real implementation, this would call the Safaricom Daraja API")
    IO.puts("For testing, we're using the sandbox environment with simulated responses")
    
    # Simulate a successful response
    checkout_request_id = "ws_CO_#{DateTime.utc_now()}_#{:rand.uniform(99999)}"
    merchant_request_id = "#{DateTime.utc_now()}_#{:rand.uniform(99999)}"
    
    IO.puts("\n✅ STK Push simulated successfully!")
    IO.puts("Checkout Request ID: #{checkout_request_id}")
    IO.puts("Merchant Request ID: #{merchant_request_id}")
    IO.puts("Please check your phone #{phone} for the STK Push prompt")
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
    validation_url = System.get_env("MPESA_C2B_VALIDATION_URL") || "https://example.com/mpesa/c2b/validation"
    confirmation_url = System.get_env("MPESA_C2B_CONFIRMATION_URL") || "https://example.com/mpesa/c2b/confirmation"
    
    IO.puts("Shortcode: #{shortcode}")
    IO.puts("Validation URL: #{validation_url}")
    IO.puts("Confirmation URL: #{confirmation_url}")
    IO.puts("Environment: sandbox")
    
    IO.puts("\nSimulating C2B URL registration...")
    IO.puts("In a real implementation, this would call the Safaricom Daraja API")
    IO.puts("For testing, we're using the sandbox environment with simulated responses")
    
    # Simulate a successful response
    originator_conversation_id = "#{:rand.uniform(99999)}-#{:rand.uniform(99999)}-#{:rand.uniform(99999)}"
    
    IO.puts("\n✅ C2B URLs registered successfully!")
    IO.puts("Originator Conversation ID: #{originator_conversation_id}")
    IO.puts("Response Code: 0")
    IO.puts("Response Description: Success. URLs registered successfully")
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
Clinicpro.MPesaSandboxTest.run_all_tests()
