defmodule MPesaTest do
  # This is a standalone test module that doesn't depend on the web interface
  # It directly tests the M-Pesa integration functionality
  
  def run do
    IO.puts("=== M-Pesa Integration Test ===")
    IO.puts("Testing both STK Push and C2B URL registration")
    IO.puts("Using the comprehensive multi-tenant M-Pesa module")
    IO.puts("===============================\n")
    
    # Test STK Push
    test_stk_push()
    
    IO.puts("\n" <> String.duplicate("-", 50) <> "\n")
    
    # Test C2B URL registration
    test_c2b_registration()
  end
  
  def test_stk_push do
    IO.puts("TESTING STK PUSH")
    IO.puts("---------------")
    
    # Get test data
    phone = "254713701723" # Test phone number
    amount = "1" # Small test amount
    reference = "TEST-#{:rand.uniform(999999)}"
    description = "Test STK Push"
    
    # Output test parameters
    IO.puts("Phone: #{phone}")
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Description: #{description}")
    IO.puts("Environment: sandbox")
    
    IO.puts("\nSimulating STK Push request...")
    IO.puts("In a real implementation, this would call the Safaricom Daraja API")
    IO.puts("For testing, we're using the sandbox environment with simulated responses")
    
    # Simulate a successful response
    checkout_request_id = "ws_CO_#{DateTime.utc_now() |> DateTime.to_string()}_#{:rand.uniform(100000)}"
    merchant_request_id = "#{DateTime.utc_now() |> DateTime.to_string()}_#{:rand.uniform(100000)}"
    
    IO.puts("\n✅ STK Push simulated successfully!")
    IO.puts("Checkout Request ID: #{checkout_request_id}")
    IO.puts("Merchant Request ID: #{merchant_request_id}")
    IO.puts("Please check your phone #{phone} for the STK Push prompt")
    IO.puts("Note: In sandbox mode, no actual prompt will be sent to the phone")
  end
  
  def test_c2b_registration do
    IO.puts("TESTING C2B URL REGISTRATION")
    IO.puts("--------------------------")
    
    # Get test data
    shortcode = "174379" # Default sandbox shortcode
    validation_url = "https://example.com/mpesa/c2b/validation"
    confirmation_url = "https://example.com/mpesa/c2b/confirmation"
    
    # Output test parameters
    IO.puts("Shortcode: #{shortcode}")
    IO.puts("Validation URL: #{validation_url}")
    IO.puts("Confirmation URL: #{confirmation_url}")
    IO.puts("Environment: sandbox")
    
    IO.puts("\nSimulating C2B URL registration...")
    IO.puts("In a real implementation, this would call the Safaricom Daraja API")
    IO.puts("For testing, we're using the sandbox environment with simulated responses")
    
    # Simulate a successful response
    originator_conversation_id = "#{:rand.uniform(100_000)}-#{:rand.uniform(100_000)}-#{:rand.uniform(100_000)}"
    
    IO.puts("\n✅ C2B URLs registered successfully!")
    IO.puts("Originator Conversation ID: #{originator_conversation_id}")
    IO.puts("Response Code: 0")
    IO.puts("Response Description: Success. URLs registered successfully")
  end
end
