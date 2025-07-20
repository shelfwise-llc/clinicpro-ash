#!/usr/bin/env elixir

# This script tests the AuthPlaceholder module without depending on the rest of the application
# Run it with: elixir test_auth_placeholder.exs

defmodule AuthPlaceholderTest do
  @moduledoc """
  Standalone test for the AuthPlaceholder module.
  """

  # Copy of the AuthPlaceholder module
  defmodule AuthPlaceholder do
    require Logger

    @doc """
    Generate a simple authentication token for a user.

    For development and testing only.
    """
    def generate_token_for_user(user_id) do
      # For development, just generate a token string
      token_string = generate_random_token()
      
      # Log the token for development purposes
      Logger.info("Generated token for user #{user_id}: #{token_string}")
      
      # Return a simple token structure with user info for development
      {:ok, %{
        token: token_string,
        user: %{
          id: user_id,
          role: if(String.contains?(user_id, "doctor"), do: "doctor", else: "patient")
        }
      }}
    end

    @doc """
    Authenticate a user by their email address.

    For development and testing only.
    """
    def authenticate_by_email(email) do
      # For development, hardcode the user IDs
      user_id = case email do
        "doctor@clinicpro.com" -> "doctor-id-123"
        "patient@clinicpro.com" -> "patient-id-456"
        _ -> nil
      end
      
      if user_id do
        generate_token_for_user(user_id)
      else
        {:error, "User not found"}
      end
    end

    @doc """
    Authenticate a user by their credentials.

    For development and testing only.
    """
    def authenticate_by_credentials(email, password) do
      # For development, hardcode the credentials
      case {email, password} do
        {"doctor@clinicpro.com", "doctor123"} -> generate_token_for_user("doctor-id-123")
        {"patient@clinicpro.com", "patient123"} -> generate_token_for_user("patient-id-456")
        _ -> {:error, "Invalid credentials"}
      end
    end

    @doc """
    Verify a token is valid.

    For development and testing only.
    """
    def verify_token(token_string) do
      # For development, always return success
      # In a real implementation, this would verify the token signature
      # and check if it's expired
      {:ok, %{
        token: token_string, 
        valid: true,
        user: %{
          id: "user-id-from-token",
          role: "role-from-token"
        }
      }}
    end

    # Generate a random token string
    defp generate_random_token do
      :crypto.strong_rand_bytes(32) |> Base.encode64()
    end
  end

  def run_tests do
    IO.puts("\n=== Testing AuthPlaceholder Module ===\n")
    
    # Test generate_token_for_user
    IO.puts("Testing generate_token_for_user...")
    {:ok, token} = AuthPlaceholder.generate_token_for_user("test-user-id")
    IO.puts("  ✓ Generated token: #{token.token}")
    IO.puts("  ✓ User ID: #{token.user.id}")
    IO.puts("  ✓ User role: #{token.user.role}")
    
    # Test authenticate_by_email with doctor
    IO.puts("\nTesting authenticate_by_email with doctor...")
    {:ok, doctor_token} = AuthPlaceholder.authenticate_by_email("doctor@clinicpro.com")
    IO.puts("  ✓ Generated token for doctor: #{doctor_token.token}")
    IO.puts("  ✓ Doctor ID: #{doctor_token.user.id}")
    IO.puts("  ✓ Doctor role: #{doctor_token.user.role}")
    
    # Test authenticate_by_email with patient
    IO.puts("\nTesting authenticate_by_email with patient...")
    {:ok, patient_token} = AuthPlaceholder.authenticate_by_email("patient@clinicpro.com")
    IO.puts("  ✓ Generated token for patient: #{patient_token.token}")
    IO.puts("  ✓ Patient ID: #{patient_token.user.id}")
    IO.puts("  ✓ Patient role: #{patient_token.user.role}")
    
    # Test authenticate_by_email with unknown email
    IO.puts("\nTesting authenticate_by_email with unknown email...")
    result = AuthPlaceholder.authenticate_by_email("unknown@example.com")
    IO.puts("  ✓ Result: #{inspect(result)}")
    
    # Test authenticate_by_credentials
    IO.puts("\nTesting authenticate_by_credentials...")
    {:ok, doctor_token2} = AuthPlaceholder.authenticate_by_credentials("doctor@clinicpro.com", "doctor123")
    IO.puts("  ✓ Generated token for doctor: #{doctor_token2.token}")
    
    # Test verify_token
    IO.puts("\nTesting verify_token...")
    {:ok, verified} = AuthPlaceholder.verify_token("some-random-token")
    IO.puts("  ✓ Token verified: #{inspect(verified.valid)}")
    IO.puts("  ✓ User ID from token: #{verified.user.id}")
    
    IO.puts("\n=== All tests passed! ===\n")
  end
end

# Run the tests
AuthPlaceholderTest.run_tests()
