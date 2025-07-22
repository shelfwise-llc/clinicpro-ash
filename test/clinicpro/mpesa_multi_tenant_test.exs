defmodule Clinicpro.MPesaMultiTenantTest do
  @moduledoc """
  Test script for verifying the multi-tenant functionality of the M-Pesa integration.
  This script uses mocked clinic IDs and API responses to test the isolation of configurations,
  transactions, and callbacks across different clinics.
  
  Run with: mix run test/clinicpro/mpesa_multi_tenant_test.exs
  """
  
  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, Transaction}
  alias Clinicpro.Repo
  
  require Logger
  
  # Use UUIDs for clinic IDs to match the database schema
  @clinic_a_id "6ba7b810-9dad-11d1-80b4-00c04fd430c8" # Test Clinic A
  @clinic_b_id "6ba7b811-9dad-11d1-80b4-00c04fd430c8" # Test Clinic B
  
  def run do
    IO.puts("\n=== ClinicPro M-Pesa Multi-Tenant Tests ===")
    IO.puts("Testing the M-Pesa functionality with multi-tenant support")
    IO.puts("All tests run in sandbox mode - no real transactions")
    IO.puts("===========================================\n")
    
    IO.puts("Using mocked clinic IDs:")
    IO.puts("Clinic A ID: #{@clinic_a_id}")
    IO.puts("Clinic B ID: #{@clinic_b_id}\n")
    
    # Setup mocks for external API calls
    setup_mocks()
    
    # Test configuration management
    test_config_management()
    
    # Test STK Push isolation
    test_stk_push_isolation()
    
    # Test C2B URL registration isolation
    test_c2b_registration_isolation()
    
    # Test transaction isolation
    test_transaction_isolation()
    
    # Test edge cases
    test_edge_cases()
    
    IO.puts("\n=== Tests Completed ===")
  end
  
  defp setup_mocks do
    IO.puts("Setting up mocks for external API calls...")
    
    # Mock the STK Push module
    if Code.ensure_loaded?(Clinicpro.MPesa.STKPush) do
      :code.purge(Clinicpro.MPesa.STKPush)
      :code.delete(Clinicpro.MPesa.STKPush)
      
      defmodule Clinicpro.MPesa.STKPush do
        def request(config, phone, amount, reference, description) do
          # Return different responses based on the clinic ID
          checkout_request_id = case config.clinic_id do
            "6ba7b810-9dad-11d1-80b4-00c04fd430c8" -> "ws_CO_A_#{DateTime.utc_now() |> DateTime.to_unix()}"
            "6ba7b811-9dad-11d1-80b4-00c04fd430c8" -> "ws_CO_B_#{DateTime.utc_now() |> DateTime.to_unix()}"
            _ -> "ws_CO_#{DateTime.utc_now() |> DateTime.to_unix()}"
          end
          
          merchant_request_id = "#{:rand.uniform(100000)}-#{:rand.uniform(100000)}-#{config.clinic_id}"
          
          {:ok, %{
            "MerchantRequestID" => merchant_request_id,
            "CheckoutRequestID" => checkout_request_id,
            "ResponseCode" => "0",
            "ResponseDescription" => "Success. Request accepted for processing",
            "CustomerMessage" => "Success. Request accepted for processing"
          }}
        end
      end
    end
    
    # Mock the C2B module
    if Code.ensure_loaded?(Clinicpro.MPesa.C2B) do
      :code.purge(Clinicpro.MPesa.C2B)
      :code.delete(Clinicpro.MPesa.C2B)
      
      defmodule Clinicpro.MPesa.C2B do
        def register_urls(config) do
          # Return different responses based on the clinic ID
          conversation_id = case config.clinic_id do
            "6ba7b810-9dad-11d1-80b4-00c04fd430c8" -> "c2b-conv-A-#{:rand.uniform(100000)}"
            "6ba7b811-9dad-11d1-80b4-00c04fd430c8" -> "c2b-conv-B-#{:rand.uniform(100000)}"
            _ -> "c2b-conv-#{:rand.uniform(100000)}"
          end
          
          {:ok, %{
            "ResponseCode" => "0",
            "ResponseDescription" => "Success",
            "OriginatorCoversationID" => conversation_id
          }}
        end
      end
    end
    
    IO.puts("✅ Mocks setup complete")
  end
  
  defp test_config_management do
    IO.puts("\n=== Testing Configuration Management ===")
    
    # Create config for Clinic A
    IO.puts("Creating config for Clinic A...")
    config_a_result = MPesa.create_config(%{
      clinic_id: @clinic_a_id,
      consumer_key: "test_key_a",
      consumer_secret: "test_secret_a",
      passkey: "test_passkey_a",
      shortcode: "123456",
      environment: "sandbox"
    })
    
    case config_a_result do
      {:ok, _config} -> IO.puts("✅ Clinic A config created successfully")
      {:error, reason} -> IO.puts("❌ Failed to create Clinic A config: #{inspect(reason)}")
    end
    
    # Create config for Clinic B
    IO.puts("\nCreating config for Clinic B...")
    config_b_result = MPesa.create_config(%{
      clinic_id: @clinic_b_id,
      consumer_key: "test_key_b",
      consumer_secret: "test_secret_b",
      passkey: "test_passkey_b",
      shortcode: "654321",
      environment: "sandbox"
    })
    
    case config_b_result do
      {:ok, _config} -> IO.puts("✅ Clinic B config created successfully")
      {:error, reason} -> IO.puts("❌ Failed to create Clinic B config: #{inspect(reason)}")
    end
    
    # Retrieve and verify configs
    IO.puts("\nRetrieving configs for both clinics...")
    
    case Config.get_for_clinic(@clinic_a_id) do
      {:ok, config_a} -> 
        IO.puts("✅ Retrieved Clinic A config")
        IO.puts("   Consumer Key: #{config_a.consumer_key}")
        IO.puts("   Shortcode: #{config_a.shortcode}")
        
        # Verify this is the correct config
        if config_a.consumer_key == "test_key_a" do
          IO.puts("✅ Config data matches Clinic A")
        else
          IO.puts("❌ Config data does not match Clinic A")
        end
      {:error, reason} -> 
        IO.puts("❌ Failed to retrieve Clinic A config: #{inspect(reason)}")
    end
    
    case Config.get_for_clinic(@clinic_b_id) do
      {:ok, config_b} -> 
        IO.puts("\n✅ Retrieved Clinic B config")
        IO.puts("   Consumer Key: #{config_b.consumer_key}")
        IO.puts("   Shortcode: #{config_b.shortcode}")
        
        # Verify this is the correct config
        if config_b.consumer_key == "test_key_b" do
          IO.puts("✅ Config data matches Clinic B")
        else
          IO.puts("❌ Config data does not match Clinic B")
        end
      {:error, reason} -> 
        IO.puts("\n❌ Failed to retrieve Clinic B config: #{inspect(reason)}")
    end
  end
  
  defp test_stk_push_isolation do
    IO.puts("\n=== Testing STK Push Multi-Tenant Isolation ===")
    
    # Initiate STK Push for Clinic A
    IO.puts("Initiating STK Push for Clinic A...")
    stk_a_result = MPesa.initiate_stk_push(
      @clinic_a_id,
      "254712345678",
      100,
      "CLINIC-A-REF",
      "Clinic A Payment"
    )
    
    case stk_a_result do
      {:ok, transaction_a} -> 
        IO.puts("✅ STK Push initiated for Clinic A")
        IO.puts("   Transaction ID: #{transaction_a.id}")
        IO.puts("   Checkout Request ID: #{transaction_a.checkout_request_id}")
        IO.puts("   Status: #{transaction_a.status}")
        IO.puts("   Clinic ID: #{transaction_a.clinic_id}")
        
        # Verify clinic ID is correctly set
        if transaction_a.clinic_id == @clinic_a_id do
          IO.puts("✅ Transaction correctly associated with Clinic A")
        else
          IO.puts("❌ Transaction not correctly associated with Clinic A")
        end
      {:error, reason} -> 
        IO.puts("❌ Failed to initiate STK Push for Clinic A: #{inspect(reason)}")
    end
    
    # Initiate STK Push for Clinic B
    IO.puts("\nInitiating STK Push for Clinic B...")
    stk_b_result = MPesa.initiate_stk_push(
      @clinic_b_id,
      "254712345678",
      200,
      "CLINIC-B-REF",
      "Clinic B Payment"
    )
    
    case stk_b_result do
      {:ok, transaction_b} -> 
        IO.puts("✅ STK Push initiated for Clinic B")
        IO.puts("   Transaction ID: #{transaction_b.id}")
        IO.puts("   Checkout Request ID: #{transaction_b.checkout_request_id}")
        IO.puts("   Status: #{transaction_b.status}")
        IO.puts("   Clinic ID: #{transaction_b.clinic_id}")
        
        # Verify clinic ID is correctly set
        if transaction_b.clinic_id == @clinic_b_id do
          IO.puts("✅ Transaction correctly associated with Clinic B")
        else
          IO.puts("❌ Transaction not correctly associated with Clinic B")
        end
      {:error, reason} -> 
        IO.puts("❌ Failed to initiate STK Push for Clinic B: #{inspect(reason)}")
    end
    
    # Process STK callbacks
    IO.puts("\nProcessing STK callbacks...")
    
    # Get the transactions
    transactions_a = Transaction.find_by_reference("CLINIC-A-REF")
    transactions_b = Transaction.find_by_reference("CLINIC-B-REF")
    
    # Process callback for Clinic A if transaction exists
    if transactions_a do
      transaction_a = List.first(transactions_a)
      
      # Create a mock callback payload
      payload_a = %{
        "Body" => %{
          "stkCallback" => %{
            "MerchantRequestID" => transaction_a.merchant_request_id,
            "CheckoutRequestID" => transaction_a.checkout_request_id,
            "ResultCode" => 0,
            "ResultDesc" => "The service request is processed successfully.",
            "CallbackMetadata" => %{
              "Item" => [
                %{"Name" => "Amount", "Value" => 100},
                %{"Name" => "MpesaReceiptNumber", "Value" => "RECEIPT-A"},
                %{"Name" => "TransactionDate", "Value" => 20250722100436},
                %{"Name" => "PhoneNumber", "Value" => 254712345678}
              ]
            }
          }
        }
      }
      
      # Process the callback
      case MPesa.process_stk_callback(payload_a) do
        {:ok, updated_transaction} -> 
          IO.puts("✅ STK callback processed for Clinic A")
          IO.puts("   Transaction Status: #{updated_transaction.status}")
          IO.puts("   Receipt Number: #{updated_transaction.receipt_number}")
          IO.puts("   Clinic ID: #{updated_transaction.clinic_id}")
        {:error, reason} -> 
          IO.puts("❌ Failed to process STK callback for Clinic A: #{inspect(reason)}")
      end
    else
      IO.puts("❌ Transaction for Clinic A not found")
    end
    
    # Process callback for Clinic B if transaction exists
    if transactions_b do
      transaction_b = List.first(transactions_b)
      
      # Create a mock callback payload
      payload_b = %{
        "Body" => %{
          "stkCallback" => %{
            "MerchantRequestID" => transaction_b.merchant_request_id,
            "CheckoutRequestID" => transaction_b.checkout_request_id,
            "ResultCode" => 0,
            "ResultDesc" => "The service request is processed successfully.",
            "CallbackMetadata" => %{
              "Item" => [
                %{"Name" => "Amount", "Value" => 200},
                %{"Name" => "MpesaReceiptNumber", "Value" => "RECEIPT-B"},
                %{"Name" => "TransactionDate", "Value" => 20250722100436},
                %{"Name" => "PhoneNumber", "Value" => 254712345678}
              ]
            }
          }
        }
      }
      
      # Process the callback
      case MPesa.process_stk_callback(payload_b) do
        {:ok, updated_transaction} -> 
          IO.puts("\n✅ STK callback processed for Clinic B")
          IO.puts("   Transaction Status: #{updated_transaction.status}")
          IO.puts("   Receipt Number: #{updated_transaction.receipt_number}")
          IO.puts("   Clinic ID: #{updated_transaction.clinic_id}")
        {:error, reason} -> 
          IO.puts("\n❌ Failed to process STK callback for Clinic B: #{inspect(reason)}")
      end
    else
      IO.puts("\n❌ Transaction for Clinic B not found")
    end
  end
  
  defp test_c2b_registration_isolation do
    IO.puts("\n=== Testing C2B URL Registration Isolation ===")
    
    # Register C2B URLs for Clinic A
    IO.puts("Registering C2B URLs for Clinic A...")
    c2b_a_result = MPesa.register_c2b_urls(@clinic_a_id)
    
    case c2b_a_result do
      {:ok, response} -> 
        IO.puts("✅ C2B URLs registered for Clinic A")
        IO.puts("   Response: #{inspect(response)}")
      {:error, reason} -> 
        IO.puts("❌ Failed to register C2B URLs for Clinic A: #{inspect(reason)}")
    end
    
    # Register C2B URLs for Clinic B
    IO.puts("\nRegistering C2B URLs for Clinic B...")
    c2b_b_result = MPesa.register_c2b_urls(@clinic_b_id)
    
    case c2b_b_result do
      {:ok, response} -> 
        IO.puts("✅ C2B URLs registered for Clinic B")
        IO.puts("   Response: #{inspect(response)}")
      {:error, reason} -> 
        IO.puts("❌ Failed to register C2B URLs for Clinic B: #{inspect(reason)}")
    end
    
    # Process C2B callback for Clinic A
    IO.puts("\nProcessing C2B callback for Clinic A...")
    
    # Create a mock C2B callback payload for Clinic A
    payload_a = %{
      "TransactionType" => "Pay Bill",
      "TransID" => "C2B-A",
      "TransTime" => "20250722100436",
      "TransAmount" => "100.00",
      "BusinessShortCode" => "123456",
      "BillRefNumber" => "CLINIC-A-C2B-REF",
      "InvoiceNumber" => "",
      "OrgAccountBalance" => "",
      "ThirdPartyTransID" => "",
      "MSISDN" => "254712345678",
      "FirstName" => "John",
      "MiddleName" => "",
      "LastName" => "Doe"
    }
    
    # Process the callback
    case MPesa.process_c2b_callback(payload_a) do
      {:ok, transaction} -> 
        IO.puts("✅ C2B callback processed for Clinic A")
        IO.puts("   Transaction Status: #{transaction.status}")
        IO.puts("   Receipt Number: #{transaction.receipt_number}")
        IO.puts("   Clinic ID: #{transaction.clinic_id}")
        
        # Verify clinic ID is correctly identified from shortcode
        if transaction.clinic_id == @clinic_a_id do
          IO.puts("✅ Transaction correctly associated with Clinic A based on shortcode")
        else
          IO.puts("❌ Transaction not correctly associated with Clinic A")
        end
      {:error, reason} -> 
        IO.puts("❌ Failed to process C2B callback for Clinic A: #{inspect(reason)}")
    end
    
    # Process C2B callback for Clinic B
    IO.puts("\nProcessing C2B callback for Clinic B...")
    
    # Create a mock C2B callback payload for Clinic B
    payload_b = %{
      "TransactionType" => "Pay Bill",
      "TransID" => "C2B-B",
      "TransTime" => "20250722100436",
      "TransAmount" => "200.00",
      "BusinessShortCode" => "654321",
      "BillRefNumber" => "CLINIC-B-C2B-REF",
      "InvoiceNumber" => "",
      "OrgAccountBalance" => "",
      "ThirdPartyTransID" => "",
      "MSISDN" => "254712345678",
      "FirstName" => "Jane",
      "MiddleName" => "",
      "LastName" => "Doe"
    }
    
    # Process the callback
    case MPesa.process_c2b_callback(payload_b) do
      {:ok, transaction} -> 
        IO.puts("✅ C2B callback processed for Clinic B")
        IO.puts("   Transaction Status: #{transaction.status}")
        IO.puts("   Receipt Number: #{transaction.receipt_number}")
        IO.puts("   Clinic ID: #{transaction.clinic_id}")
        
        # Verify clinic ID is correctly identified from shortcode
        if transaction.clinic_id == @clinic_b_id do
          IO.puts("✅ Transaction correctly associated with Clinic B based on shortcode")
        else
          IO.puts("❌ Transaction not correctly associated with Clinic B")
        end
      {:error, reason} -> 
        IO.puts("❌ Failed to process C2B callback for Clinic B: #{inspect(reason)}")
    end
  end
  
  defp test_transaction_isolation do
    IO.puts("\n=== Testing Transaction Isolation ===")
    
    # List transactions for Clinic A
    IO.puts("Listing transactions for Clinic A...")
    transactions_a = MPesa.list_transactions(@clinic_a_id)
    
    IO.puts("✅ Found #{length(transactions_a)} transactions for Clinic A")
    if length(transactions_a) > 0 do
      transaction_a = List.first(transactions_a)
      IO.puts("   First transaction reference: #{transaction_a.reference}")
      IO.puts("   Clinic ID: #{transaction_a.clinic_id}")
      
      # Verify all transactions belong to Clinic A
      all_clinic_a = Enum.all?(transactions_a, fn t -> t.clinic_id == @clinic_a_id end)
      if all_clinic_a do
        IO.puts("✅ All transactions correctly associated with Clinic A")
      else
        IO.puts("❌ Some transactions not correctly associated with Clinic A")
      end
    end
    
    # List transactions for Clinic B
    IO.puts("\nListing transactions for Clinic B...")
    transactions_b = MPesa.list_transactions(@clinic_b_id)
    
    IO.puts("✅ Found #{length(transactions_b)} transactions for Clinic B")
    if length(transactions_b) > 0 do
      transaction_b = List.first(transactions_b)
      IO.puts("   First transaction reference: #{transaction_b.reference}")
      IO.puts("   Clinic ID: #{transaction_b.clinic_id}")
      
      # Verify all transactions belong to Clinic B
      all_clinic_b = Enum.all?(transactions_b, fn t -> t.clinic_id == @clinic_b_id end)
      if all_clinic_b do
        IO.puts("✅ All transactions correctly associated with Clinic B")
      else
        IO.puts("❌ Some transactions not correctly associated with Clinic B")
      end
    end
  end
  
  defp test_edge_cases do
    IO.puts("\n=== Testing Edge Cases ===")
    
    # Test missing configuration
    IO.puts("Testing with non-existent clinic ID...")
    non_existent_id = "00000000-0000-0000-0000-000000000000"
    result = MPesa.initiate_stk_push(
      non_existent_id,
      "254712345678",
      100,
      "TEST-REF",
      "Test Payment"
    )
    
    case result do
      {:error, :mpesa_config_not_found} -> 
        IO.puts("✅ Correctly returned error for missing configuration")
      other -> 
        IO.puts("❌ Unexpected result for missing configuration: #{inspect(other)}")
    end
    
    # Test invalid transaction data
    IO.puts("\nTesting with invalid transaction data...")
    result = MPesa.initiate_stk_push(
      @clinic_a_id,
      "invalid_phone",
      -100,
      "",
      "Invalid Payment"
    )
    
    case result do
      {:error, :invalid_transaction_data} -> 
        IO.puts("✅ Correctly returned error for invalid transaction data")
      other -> 
        IO.puts("❌ Unexpected result for invalid transaction data: #{inspect(other)}")
    end
    
    # Test cross-clinic transaction access
    IO.puts("\nTesting cross-clinic transaction access...")
    
    # Create a transaction for Clinic A
    {:ok, transaction_a} = MPesa.initiate_stk_push(
      @clinic_a_id,
      "254712345678",
      100,
      "CROSS-ACCESS-TEST-A",
      "Clinic A Payment"
    )
    
    # Try to access it using Clinic B's ID
    case MPesa.get_transaction(@clinic_b_id, transaction_a.id) do
      {:error, :transaction_not_found} -> 
        IO.puts("✅ Correctly prevented cross-clinic transaction access")
      {:ok, _} -> 
        IO.puts("❌ Failed to prevent cross-clinic transaction access")
      other -> 
        IO.puts("❌ Unexpected result for cross-clinic access: #{inspect(other)}")
    end
  end
end

# Run the tests when this file is executed directly
Clinicpro.MPesaMultiTenantTest.run()
