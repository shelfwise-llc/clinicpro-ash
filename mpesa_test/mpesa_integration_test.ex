defmodule Clinicpro.MPesaIntegrationTest do
  @moduledoc """
  Integration test for the Clinicpro.MPesa module.
  This module tests the actual M-Pesa implementation without relying on the web interface.
  """

  # Import the actual M-Pesa module
  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.Config
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Repo

  @doc """
  Run all M-Pesa integration tests
  """
  def run_all_tests do
    IO.puts("=== ClinicPro M-Pesa Integration Tests ===")
    IO.puts("Testing with the comprehensive multi-tenant implementation")
    IO.puts("All tests run in sandbox mode - no real transactions")
    IO.puts("===========================================\n")
    
    # Ensure we have a test clinic and configuration
    {clinic_id, config} = ensure_test_environment()
    
    # Run STK Push test
    run_stk_push_test(clinic_id, config)
    
    IO.puts("\n" <> String.duplicate("-", 60) <> "\n")
    
    # Run C2B URL registration test
    run_c2b_registration_test(clinic_id, config)
  end

  @doc """
  Test the STK Push functionality
  """
  def run_stk_push_test(clinic_id \\ nil, config \\ nil) do
    IO.puts("TESTING STK PUSH FUNCTIONALITY")
    IO.puts("-----------------------------")
    
    # Get or create test environment if not provided
    {clinic_id, config} = if clinic_id && config do
      {clinic_id, config}
    else
      ensure_test_environment()
    end
    
    # Get test phone number from environment or use default
    phone = format_phone(System.get_env("MPESA_TEST_PHONE") || "0713701723")
    
    # Create a unique reference for this test
    reference = "TEST-#{:rand.uniform(999999)}"
    
    # Use a small amount for testing
    amount = "1"
    
    # Description for the transaction
    description = "M-Pesa Integration Test"
    
    # Display test parameters
    IO.puts("Test clinic ID: #{clinic_id}")
    IO.puts("Phone number: #{phone}")
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Environment: #{config.environment}")
    IO.puts("Shortcode: #{config.shortcode}")
    
    IO.puts("\nInitiating STK Push request...")
    
    # Call the actual M-Pesa module to initiate STK Push
    case MPesa.initiate_stk_push(clinic_id, phone, amount, reference, description) do
      {:ok, transaction} ->
        IO.puts("\n✅ STK Push initiated successfully!")
        IO.puts("Transaction ID: #{transaction.id}")
        IO.puts("Checkout Request ID: #{transaction.checkout_request_id}")
        IO.puts("Merchant Request ID: #{transaction.merchant_request_id}")
        IO.puts("Status: #{transaction.status}")
        IO.puts("\nNote: In sandbox mode, no actual prompt will be sent to the phone.")
        IO.puts("The transaction will remain in 'pending' status.")
        
      {:error, reason} ->
        IO.puts("\n❌ Failed to initiate STK Push: #{inspect(reason)}")
    end
  end

  @doc """
  Test the C2B URL registration functionality
  """
  def run_c2b_registration_test(clinic_id \\ nil, config \\ nil) do
    IO.puts("TESTING C2B URL REGISTRATION")
    IO.puts("---------------------------")
    
    # Get or create test environment if not provided
    {clinic_id, config} = if clinic_id && config do
      {clinic_id, config}
    else
      ensure_test_environment()
    end
    
    # Display test parameters
    IO.puts("Test clinic ID: #{clinic_id}")
    IO.puts("Environment: #{config.environment}")
    IO.puts("C2B Shortcode: #{config.c2b_shortcode}")
    IO.puts("Validation URL: #{config.c2b_validation_url}")
    IO.puts("Confirmation URL: #{config.c2b_confirmation_url}")
    
    IO.puts("\nRegistering C2B URLs...")
    
    # Call the actual M-Pesa module to register C2B URLs
    case MPesa.register_c2b_urls(clinic_id) do
      {:ok, response} ->
        IO.puts("\n✅ C2B URLs registered successfully!")
        IO.puts("Response: #{inspect(response)}")
        IO.puts("\nNote: In sandbox mode, this is a simulated response.")
        
      {:error, reason} ->
        IO.puts("\n❌ Failed to register C2B URLs: #{inspect(reason)}")
    end
  end

  # Helper functions

  defp ensure_test_environment do
    # Get or create a test clinic
    clinic = get_or_create_test_clinic()
    
    # Get or create M-Pesa configuration for the test clinic
    config = case Config.get_for_clinic(clinic.id) do
      {:ok, config} -> config
      {:error, _reason} -> create_test_config(clinic.id)
    end
    
    {clinic.id, config}
  end

  defp get_or_create_test_clinic do
    # Try to find an existing clinic
    case get_first_clinic() do
      nil ->
        # Create a test clinic if none exists
        IO.puts("Creating test clinic...")
        {:ok, clinic} = create_test_clinic()
        clinic
        
      clinic -> clinic
    end
  end

  defp get_first_clinic do
    # This assumes there's a Doctor module that represents clinics
    # Adjust according to your actual data model
    case Clinicpro.AdminBypass.Doctor |> Repo.all() |> List.first() do
      nil -> nil
      clinic -> clinic
    end
  end

  defp create_test_clinic do
    # Create a test clinic
    # Adjust according to your actual data model
    Clinicpro.AdminBypass.Doctor.changeset(%Clinicpro.AdminBypass.Doctor{}, %{
      name: "Test Clinic",
      email: "test@example.com",
      phone: "0700000000"
    }) |> Repo.insert()
  end

  defp create_test_config(clinic_id) do
    # Create a test M-Pesa configuration for the clinic
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
      "clinic_id" => clinic_id
    }
    
    {:ok, config} = MPesa.create_config(attrs)
    config
  end

  defp format_phone("0" <> rest = _phone) do
    "254#{rest}"
  end
  
  defp format_phone(phone), do: phone
end
