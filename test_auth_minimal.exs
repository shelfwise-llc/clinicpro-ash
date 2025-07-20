#!/usr/bin/env elixir

# This script tests the AuthPlaceholder module without requiring the full application to compile
# Run it with: elixir test_auth_minimal.exs

# First, define the AuthPlaceholder module exactly as it is in the application
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

# Now, define and run the tests
defmodule AuthPlaceholderTest do
  @moduledoc """
  Tests for the AuthPlaceholder module.
  """

  def run_tests do
    IO.puts("\n=== Running AuthPlaceholder Tests ===\n")
    
    # Test 1: generate_token_for_user
    IO.puts("Test 1: generate_token_for_user")
    user_id = "test-user-id"
    {:ok, token} = AuthPlaceholder.generate_token_for_user(user_id)
    
    assert_true(is_map(token), "Token should be a map")
    assert_true(Map.has_key?(token, :token), "Token should have a :token key")
    assert_true(is_binary(token.token), "Token.token should be a binary")
    IO.puts("✅ Test 1 passed\n")
    
    # Test 2: authenticate_by_email with doctor
    IO.puts("Test 2: authenticate_by_email with doctor")
    email = "doctor@clinicpro.com"
    {:ok, token} = AuthPlaceholder.authenticate_by_email(email)
    
    assert_true(is_map(token), "Token should be a map")
    assert_true(Map.has_key?(token, :token), "Token should have a :token key")
    assert_true(is_binary(token.token), "Token.token should be a binary")
    IO.puts("✅ Test 2 passed\n")
    
    # Test 3: authenticate_by_email with patient
    IO.puts("Test 3: authenticate_by_email with patient")
    email = "patient@clinicpro.com"
    {:ok, token} = AuthPlaceholder.authenticate_by_email(email)
    
    assert_true(is_map(token), "Token should be a map")
    assert_true(Map.has_key?(token, :token), "Token should have a :token key")
    assert_true(is_binary(token.token), "Token.token should be a binary")
    IO.puts("✅ Test 3 passed\n")
    
    # Test 4: authenticate_by_email with unknown email
    IO.puts("Test 4: authenticate_by_email with unknown email")
    email = "unknown@example.com"
    result = AuthPlaceholder.authenticate_by_email(email)
    
    assert_equal(result, {:error, "User not found"}, "Should return error for unknown email")
    IO.puts("✅ Test 4 passed\n")
    
    # Test 5: authenticate_by_credentials with valid credentials
    IO.puts("Test 5: authenticate_by_credentials with valid credentials")
    {:ok, token} = AuthPlaceholder.authenticate_by_credentials("doctor@clinicpro.com", "doctor123")
    
    assert_true(is_map(token), "Token should be a map")
    assert_true(Map.has_key?(token, :token), "Token should have a :token key")
    assert_true(is_binary(token.token), "Token.token should be a binary")
    IO.puts("✅ Test 5 passed\n")
    
    # Test 6: authenticate_by_credentials with invalid credentials
    IO.puts("Test 6: authenticate_by_credentials with invalid credentials")
    result = AuthPlaceholder.authenticate_by_credentials("doctor@clinicpro.com", "wrong")
    
    assert_equal(result, {:error, "Invalid credentials"}, "Should return error for invalid credentials")
    IO.puts("✅ Test 6 passed\n")
    
    # Test 7: verify_token
    IO.puts("Test 7: verify_token")
    token_string = "some-random-token"
    {:ok, result} = AuthPlaceholder.verify_token(token_string)
    
    assert_equal(result.token, token_string, "Verified token should match input token")
    assert_equal(result.valid, true, "Token should be valid")
    IO.puts("✅ Test 7 passed\n")
    
    IO.puts("=== All AuthPlaceholder Tests Passed! ===\n")
  end
  
  # Simple assertion helpers
  defp assert_true(value, message) do
    unless value do
      IO.puts("❌ Assertion failed: #{message}")
      System.halt(1)
    end
  end
  
  defp assert_equal(actual, expected, message) do
    unless actual == expected do
      IO.puts("❌ Assertion failed: #{message}")
      IO.puts("  Expected: #{inspect(expected)}")
      IO.puts("  Actual:   #{inspect(actual)}")
      System.halt(1)
    end
  end
end

# Run the tests
AuthPlaceholderTest.run_tests()
