defmodule Clinicpro.MPesaStandaloneTest do
  @moduledoc """
  Standalone test script for M-Pesa integration.
  Run this script with: 
  - mix run -e 'Clinicpro.MPesaStandaloneTest.run_stk_push_test()'
  - mix run -e 'Clinicpro.MPesaStandaloneTest.run_c2b_registration_test()'
  - mix run -e 'Clinicpro.MPesaStandaloneTest.run_all_tests()'
  """

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.Config
  # # alias Clinicpro.Repo

  @doc """
  Tests the STK Push functionality using the sandbox environment.
  """
  def run_stk_push_test do
    # Ensure we're in sandbox mode
    IO.puts("Starting M-Pesa STK Push test...")
    
    # Format the phone number correctly (remove leading 0 and add 254)
    phone = format_phone(System.get_env("MPESA_TEST_PHONE") || "0713701723")
    
    # Create a test _transaction reference
    reference = "TEST-#{:rand.uniform(1000000)}"
    
    # Set test amount (use a small amount for testing)
    amount = "1"
    
    # Get the first clinic from the database for testing
    clinic = get_test_clinic()
    
    # Create a test configuration if it doesn't exist
    config = ensure_test_config(clinic.id)
    
    IO.puts("Using test phone: #{phone}")
    IO.puts("Test reference: #{reference}")
    IO.puts("Test amount: #{amount} KES")
    IO.puts("Test clinic: #{clinic.name} (ID: #{clinic.id})")
    IO.puts("Environment: #{config.environment}")
    
    IO.puts("\nInitiating STK Push request...")
    
    # Initiate STK Push using the comprehensive MPesa module
    case MPesa.initiate_stk_push(clinic.id, phone, amount, reference, "Test STK Push") do
      {:ok, _transaction} ->
        IO.puts("\n✅ STK Push initiated successfully!")
        IO.puts("Transaction ID: #{_transaction.id}")
        IO.puts("Checkout Request ID: #{_transaction.checkout_request_id}")
        IO.puts("Please check your phone #{phone} for the STK Push prompt.")
        IO.puts("\nNote: In sandbox mode, no actual prompt will be sent to the phone.")
        IO.puts("The _transaction will remain in 'pending' status.")
        
      {:error, reason} ->
        IO.puts("\n❌ Failed to initiate STK Push: #{inspect(reason)}")
    end
  end
  
  @doc """
  Tests the C2B URL registration functionality using the sandbox environment.
  """
  def run_c2b_registration_test do
    IO.puts("Starting M-Pesa C2B URL registration test...")
    
    # Get the first clinic from the database for testing
    clinic = get_test_clinic()
    
    # Create a test configuration if it doesn't exist
    config = ensure_test_config(clinic.id)
    
    IO.puts("Test clinic: #{clinic.name} (ID: #{clinic.id})")
    IO.puts("Environment: #{config.environment}")
    IO.puts("C2B Shortcode: #{config.c2b_shortcode}")
    IO.puts("Validation URL: #{config.c2b_validation_url}")
    IO.puts("Confirmation URL: #{config.c2b_confirmation_url}")
    
    IO.puts("\nRegistering C2B URLs...")
    
    # Register C2B URLs using the comprehensive MPesa module
    case MPesa.register_c2b_urls(clinic.id) do
      {:ok, response} ->
        IO.puts("\n✅ C2B URLs registered successfully!")
        IO.puts("Response: #{inspect(response)}")
        IO.puts("\nNote: In sandbox mode, this is a simulated response.")
        IO.puts("In production, the URLs would be registered with Safaricom's M-Pesa API.")
        
      {:error, reason} ->
        IO.puts("\n❌ Failed to register C2B URLs: #{inspect(reason)}")
    end
  end
  
  @doc """
  Runs both STK Push and C2B URL registration tests.
  """
  def run_all_tests do
    run_stk_push_test()
    IO.puts("\n" <> String.duplicate("-", 80) <> "\n")
    run_c2b_registration_test()
  end
  
  # Private helper functions
  
  defp format_phone("0" <> rest = _phone) do
    "254#{rest}"
  end
  
  defp format_phone(phone), do: phone
  
  defp get_test_clinic do
    case Clinicpro.AdminBypass.Doctor |> Repo.all() |> List.first() do
      nil ->
        # Create a test clinic if none exists
        {:ok, clinic} = Clinicpro.AdminBypass.Doctor.changeset(%Clinicpro.AdminBypass.Doctor{}, %{
          name: "Test Clinic",
          email: "test@example.com",
          phone: "0700000000"
        }) |> Repo.insert()
        clinic
        
      clinic -> clinic
    end
  end
  
  defp ensure_test_config(_clinic_id) do
    case Config.get_for_clinic(_clinic_id) do
      {:ok, config} -> config
      {:error, _reason} ->
        # Create a test configuration using environment variables
        attrs = %{
          "consumer_key" => System.get_env("MPESA_CONSUMER_KEY") || "test_consumer_key",
          "consumer_secret" => System.get_env("MPESA_CONSUMER_SECRET") || "test_consumer_secret",
          "passkey" => System.get_env("MPESA_PASSKEY") || "test_passkey",
          "shortcode" => System.get_env("MPESA_SHORTCODE") || "174379", # Default sandbox shortcode
          "c2b_shortcode" => System.get_env("MPESA_C2B_SHORTCODE") || "174379", # Default sandbox shortcode
          "environment" => "sandbox",
          "stk_callback_url" => System.get_env("MPESA_STK_CALLBACK_URL") || "https://example.com/mpesa/stk/callback",
          "c2b_validation_url" => System.get_env("MPESA_C2B_VALIDATION_URL") || "https://example.com/mpesa/c2b/validation",
          "c2b_confirmation_url" => System.get_env("MPESA_C2B_CONFIRMATION_URL") || "https://example.com/mpesa/c2b/confirmation",
          "active" => true,
          "_clinic_id" => _clinic_id
        }
        
        {:ok, config} = MPesa.create_config(attrs)
        config
    end
  end
end
