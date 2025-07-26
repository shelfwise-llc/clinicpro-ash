defmodule Clinicpro.Accounts.AuthPlaceholderTest do
  use Clinicpro.DataCase

  alias Clinicpro.Accounts.AuthPlaceholder

  describe "generate_token_for_user/1" do
    test "generates a token for a given user ID" do
      user_id = "test-user-id"
      {:ok, token} = AuthPlaceholder.generate_token_for_user(user_id)

      assert is_map(token)
      assert Map.has_key?(token, :token)
      assert is_binary(token.token)
    end
  end

  describe "authenticate_by_email/1" do
    test "returns a token when given a doctor email" do
      email = "doctor@clinicpro.com"
      {:ok, token} = AuthPlaceholder.authenticate_by_email(email)

      assert is_map(token)
      assert Map.has_key?(token, :token)
      assert is_binary(token.token)
    end

    test "returns a token when given a patient email" do
      email = "patient@clinicpro.com"
      {:ok, token} = AuthPlaceholder.authenticate_by_email(email)

      assert is_map(token)
      assert Map.has_key?(token, :token)
      assert is_binary(token.token)
    end

    test "returns an error for unknown email" do
      email = "unknown@example.com"
      result = AuthPlaceholder.authenticate_by_email(email)

      assert result == {:error, "User not found"}
    end
  end

  describe "verify_token/1" do
    test "always returns success for any token" do
      token_string = "some-random-token"
      {:ok, result} = AuthPlaceholder.verify_token(token_string)

      assert result.token == token_string
      assert result.valid == true
    end
  end
end
