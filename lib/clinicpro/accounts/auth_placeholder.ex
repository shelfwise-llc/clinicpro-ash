defmodule Clinicpro.Accounts.AuthPlaceholder do
  @moduledoc """
  Placeholder authentication module for development and testing.

  This module provides simplified authentication functions that bypass the
  full authentication flow, allowing development to proceed while
  authentication issues are being resolved.

  WARNING: This is not for production use.
  """

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
