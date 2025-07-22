defmodule Clinicpro.MPesaManualTest do
  @moduledoc """
  Manual test script for the Clinicpro.MPesa module functionality.
  This module tests the M-Pesa implementation with a focus on multi-tenant support.
  
  Run with: mix run test/clinicpro/mpesa_manual_test.exs
  """

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, Transaction}
  alias Clinicpro.Repo
  alias Clinicpro.AdminBypass.Doctor

  require Logger

  def run do
    IO.puts("\n=== ClinicPro M-Pesa Multi-Tenant Tests ===")
    IO.puts("Testing the M-Pesa functionality with multi-tenant support")
    IO.puts("All tests run in sandbox mode - no real transactions")
    IO.puts("===========================================\n")
    
    # First, get or create actual clinic records from the database
    {clinic_a_id, clinic_b_id} = get_or_create_test_clinics()
    
    IO.puts("Test Clinic A ID: #{clinic_a_id}")
    IO.puts("Test Clinic B ID: #{clinic_b_id}\n")
    
    # Test configuration management
    test_config_management(clinic_a_id, clinic_b_id)
    
    # Test STK Push
    test_stk_push(clinic_a_id, clinic_b_id)
    
    # Test C2B URL registration
    test_c2b_registration(clinic_a_id, clinic_b_id)
    
    # Test transaction isolation
    test_transaction_isolation(clinic_a_id, clinic_b_id)
    
    # Test edge cases
    test_edge_cases(clinic_a_id)
    
    IO.puts("\n=== Tests Completed ===")
  end

  defp get_or_create_test_clinics do
    # Try to find existing test clinics first
    clinic_a = Repo.get_by(Doctor, first_name: "Test Clinic", last_name: "A")
    clinic_b = Repo.get_by(Doctor, first_name: "Test Clinic", last_name: "B")
    
    # Create clinics if they don't exist
    clinic_a = if is_nil(clinic_a) do
      {:ok, clinic} = %Doctor{}
                      |> Doctor.changeset(%{
                        first_name: "Test Clinic",
                        last_name: "A",
                        email: "clinic_a@test.com",
                        phone: "254711000001",
                        specialty: "General",
                        active: true,
                        years_of_experience: 5,
                        consultation_fee: 1000
                      })
                      |> Repo.insert()
      clinic
    else
      clinic_a
    end
    
    clinic_b = if is_nil(clinic_b) do
      {:ok, clinic} = %Doctor{}
                      |> Doctor.changeset(%{
                        first_name: "Test Clinic",
                        last_name: "B",
                        email: "clinic_b@test.com",
                        phone: "254711000002",
                        specialty: "General",
                        active: true,
                        years_of_experience: 5,
                        consultation_fee: 1000
                      })
                      |> Repo.insert()
      clinic
    else
      clinic_b
    end
    
    {clinic_a.id, clinic_b.id}
  end

  defp test_config_management(clinic_a_id, clinic_b_id) do
    IO.puts("\n=== Testing Configuration Management ===")
    
    # Create config for Clinic A
    IO.puts("Creating config for Clinic A...")
    config_a_result = MPesa.create_config(%{
      clinic_id: clinic_a_id,
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
      clinic_id: clinic_b_id,
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
    
    case Config.get_for_clinic(clinic_a_id) do
      {:ok, config_a} -> 
        IO.puts("✅ Retrieved Clinic A config")
        IO.puts("   Consumer Key: #{config_a.consumer_key}")
        IO.puts("   Shortcode: #{config_a.shortcode}")
      {:error, reason} -> 
        IO.puts("❌ Failed to retrieve Clinic A config: #{inspect(reason)}")
    end
    
    case Config.get_for_clinic(clinic_b_id) do
      {:ok, config_b} -> 
        IO.puts("\n✅ Retrieved Clinic B config")
        IO.puts("   Consumer Key: #{config_b.consumer_key}")
        IO.puts("   Shortcode: #{config_b.shortcode}")
      {:error, reason} -> 
        IO.puts("\n❌ Failed to retrieve Clinic B config: #{inspect(reason)}")
    end
  end

  defp test_stk_push(clinic_a_id, clinic_b_id) do
    IO.puts("\n=== Testing STK Push Functionality ===")
    
    # Mock the STK Push request function to avoid actual API calls
    mock_stk_push_request()
    
    # Initiate STK Push for Clinic A
    IO.puts("Initiating STK Push for Clinic A...")
    stk_a_result = MPesa.initiate_stk_push(
      clinic_a_id,
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
      {:error, reason} -> 
        IO.puts("❌ Failed to initiate STK Push for Clinic A: #{inspect(reason)}")
    end
    
    # Initiate STK Push for Clinic B
    IO.puts("\nInitiating STK Push for Clinic B...")
    stk_b_result = MPesa.initiate_stk_push(
      clinic_b_id,
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
      {:error, reason} -> 
        IO.puts("❌ Failed to initiate STK Push for Clinic B: #{inspect(reason)}")
    end
    
    # Process STK callback for Clinic A
    IO.puts("\nProcessing STK callback for Clinic A...")
    
    # Get the transaction for Clinic A
    case Transaction.find_by_reference("CLINIC-A-REF") do
      nil -> 
        IO.puts("❌ Transaction for Clinic A not found")
      
      transaction_a ->
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
          {:error, reason} -> 
            IO.puts("❌ Failed to process STK callback for Clinic A: #{inspect(reason)}")
        end
    end
    
    # Process STK callback for Clinic B
    IO.puts("\nProcessing STK callback for Clinic B...")
    
    # Get the transaction for Clinic B
    case Transaction.find_by_reference("CLINIC-B-REF") do
      nil -> 
        IO.puts("❌ Transaction for Clinic B not found")
      
      transaction_b ->
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
            IO.puts("✅ STK callback processed for Clinic B")
            IO.puts("   Transaction Status: #{updated_transaction.status}")
            IO.puts("   Receipt Number: #{updated_transaction.receipt_number}")
          {:error, reason} -> 
            IO.puts("❌ Failed to process STK callback for Clinic B: #{inspect(reason)}")
        end
    end
  end

  defp test_c2b_registration(clinic_a_id, clinic_b_id) do
    IO.puts("\n=== Testing C2B URL Registration ===")
    
    # Mock the C2B URL registration function to avoid actual API calls
    mock_c2b_registration()
    
    # Register C2B URLs for Clinic A
    IO.puts("Registering C2B URLs for Clinic A...")
    c2b_a_result = MPesa.register_c2b_urls(clinic_a_id)
    
    case c2b_a_result do
      {:ok, response} -> 
        IO.puts("✅ C2B URLs registered for Clinic A")
        IO.puts("   Response: #{inspect(response)}")
      {:error, reason} -> 
        IO.puts("❌ Failed to register C2B URLs for Clinic A: #{inspect(reason)}")
    end
    
    # Register C2B URLs for Clinic B
    IO.puts("\nRegistering C2B URLs for Clinic B...")
    c2b_b_result = MPesa.register_c2b_urls(clinic_b_id)
    
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
      {:error, reason} -> 
        IO.puts("❌ Failed to process C2B callback for Clinic B: #{inspect(reason)}")
    end
  end

  defp test_transaction_isolation(clinic_a_id, clinic_b_id) do
    IO.puts("\n=== Testing Transaction Isolation ===")
    
    # List transactions for Clinic A
    IO.puts("Listing transactions for Clinic A...")
    transactions_a = MPesa.list_transactions(clinic_a_id)
    
    IO.puts("✅ Found #{length(transactions_a)} transactions for Clinic A")
    if length(transactions_a) > 0 do
      IO.puts("   First transaction reference: #{hd(transactions_a).reference}")
    end
    
    # List transactions for Clinic B
    IO.puts("\nListing transactions for Clinic B...")
    transactions_b = MPesa.list_transactions(clinic_b_id)
    
    IO.puts("✅ Found #{length(transactions_b)} transactions for Clinic B")
    if length(transactions_b) > 0 do
      IO.puts("   First transaction reference: #{hd(transactions_b).reference}")
    end
    
    # Get transaction statistics for each clinic
    IO.puts("\nGetting transaction statistics...")
    
    # This function may not exist in the original code, so we'll check first
    if function_exported?(Transaction, :get_stats_for_clinic, 1) do
      stats_a = Transaction.get_stats_for_clinic(clinic_a_id)
      stats_b = Transaction.get_stats_for_clinic(clinic_b_id)
      
      IO.puts("Clinic A statistics: #{inspect(stats_a)}")
      IO.puts("Clinic B statistics: #{inspect(stats_b)}")
    else
      IO.puts("Transaction statistics function not available")
    end
  end

  defp test_edge_cases(clinic_id) do
    IO.puts("\n=== Testing Edge Cases ===")
    
    # Test missing configuration
    IO.puts("Testing with non-existent clinic ID...")
    result = MPesa.initiate_stk_push(
      "non_existent_clinic_id",
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
      clinic_id,
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
  end

  # Helper functions to mock external API calls

  defp mock_stk_push_request do
    # This is a simplified mock that would normally be done with a proper mocking library
    # In a real test, you would use something like Mox to mock the HTTP client
    
    # For now, we'll just redefine the function in the module
    if Code.ensure_loaded?(Clinicpro.MPesa.STKPush) do
      :code.purge(Clinicpro.MPesa.STKPush)
      :code.delete(Clinicpro.MPesa.STKPush)
      
      defmodule Clinicpro.MPesa.STKPush do
        def request(_config, _phone, _amount, _reference, _description) do
          # Return a mock successful response
          {:ok, %{
            "MerchantRequestID" => "#{:rand.uniform(100000)}-#{:rand.uniform(100000)}-#{:rand.uniform(100000)}",
            "CheckoutRequestID" => "ws_CO_#{DateTime.utc_now() |> DateTime.to_unix()}_#{:rand.uniform(100000)}",
            "ResponseCode" => "0",
            "ResponseDescription" => "Success. Request accepted for processing",
            "CustomerMessage" => "Success. Request accepted for processing"
          }}
        end
        
        def query_status(_config, _checkout_request_id) do
          # Return a mock successful response
          {:ok, %{
            "ResponseCode" => "0",
            "ResponseDescription" => "The service request has been accepted successfully",
            "MerchantRequestID" => "#{:rand.uniform(100000)}-#{:rand.uniform(100000)}-#{:rand.uniform(100000)}",
            "CheckoutRequestID" => "ws_CO_#{DateTime.utc_now() |> DateTime.to_unix()}_#{:rand.uniform(100000)}",
            "ResultCode" => "0",
            "ResultDesc" => "The service request is processed successfully"
          }}
        end
      end
    end
  end

  defp mock_c2b_registration do
    # Similar to the STK Push mock, we'll redefine the C2B module
    if Code.ensure_loaded?(Clinicpro.MPesa.C2B) do
      :code.purge(Clinicpro.MPesa.C2B)
      :code.delete(Clinicpro.MPesa.C2B)
      
      defmodule Clinicpro.MPesa.C2B do
        def register_urls(_config) do
          # Return a mock successful response
          {:ok, %{
            "ResponseCode" => "0",
            "ResponseDescription" => "Success",
            "OriginatorCoversationID" => "#{:rand.uniform(100000)}-#{:rand.uniform(100000)}-#{:rand.uniform(100000)}"
          }}
        end
      end
    end
  end
end

# Run the tests when this file is executed directly
Clinicpro.MPesaManualTest.run()
