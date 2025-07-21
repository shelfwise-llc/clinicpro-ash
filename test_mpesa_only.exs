# Simple script to test only the M-Pesa module without requiring web components
# Run with: elixir -S mix run test_mpesa_only.exs

# Define a simple test module
defmodule MPesaOnlyTest do
  # Import only what we need
  alias Clinicpro.MPesa
  alias Clinicpro.Repo
  
  def run do
    IO.puts("=== ClinicPro M-Pesa Integration Test ===")
    IO.puts("Testing in sandbox mode - no real transactions")
    IO.puts("========================================\n")
    
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
    phone = format_phone(System.get_env("MPESA_TEST_PHONE") || "0713701723")
    amount = "1"
    reference = "TEST-#{:rand.uniform(999999)}"
    description = "Test STK Push"
    
    # Get or create test clinic
    clinic_id = get_test_clinic_id()
    
    # Output test parameters
    IO.puts("Phone: #{phone}")
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Clinic ID: #{clinic_id}")
    
    IO.puts("\nInitiating STK Push request...")
    
    # Call the actual M-Pesa module
    case MPesa.initiate_stk_push(clinic_id, phone, amount, reference, description) do
      {:ok, transaction} ->
        IO.puts("\n✅ STK Push initiated successfully!")
        IO.puts("Transaction ID: #{transaction.id}")
        IO.puts("Checkout Request ID: #{transaction.checkout_request_id}")
        IO.puts("Status: #{transaction.status}")
        
      {:error, reason} ->
        IO.puts("\n❌ Failed to initiate STK Push: #{inspect(reason)}")
    end
  end
  
  def test_c2b_registration do
    IO.puts("TESTING C2B URL REGISTRATION")
    IO.puts("--------------------------")
    
    # Get or create test clinic
    clinic_id = get_test_clinic_id()
    
    # Output test parameters
    IO.puts("Clinic ID: #{clinic_id}")
    
    IO.puts("\nRegistering C2B URLs...")
    
    # Call the actual M-Pesa module
    case MPesa.register_c2b_urls(clinic_id) do
      {:ok, response} ->
        IO.puts("\n✅ C2B URLs registered successfully!")
        IO.puts("Response: #{inspect(response)}")
        
      {:error, reason} ->
        IO.puts("\n❌ Failed to register C2B URLs: #{inspect(reason)}")
    end
  end
  
  # Helper functions
  
  defp format_phone("0" <> rest = _phone) do
    "254#{rest}"
  end
  
  defp format_phone(phone), do: phone
  
  defp get_test_clinic_id do
    # Try to get an existing clinic
    case Clinicpro.AdminBypass.Doctor |> Repo.all() |> List.first() do
      nil ->
        # Create a test clinic if none exists
        {:ok, clinic} = Clinicpro.AdminBypass.Doctor.changeset(%Clinicpro.AdminBypass.Doctor{}, %{
          name: "Test Clinic",
          email: "test@example.com",
          phone: "0700000000"
        }) |> Repo.insert()
        clinic.id
        
      clinic -> clinic.id
    end
  end
end

# Run the tests
MPesaOnlyTest.run()
