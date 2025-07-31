ExUnit.start()

defmodule Clinicpro.Auth.Values.AuthTokenTest do
  use ExUnit.Case, async: true

  alias Clinicpro.Auth.Values.AuthToken

  describe "new/4" do
    test "creates a new auth token" do
      token = "test_token"
      context = "magic_link"
      sent_to = "test@example.com"
      expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)

      auth_token = AuthToken.new(token, context, sent_to, expires_at)

      assert auth_token.token == token
      assert auth_token.context == context
      assert auth_token.sent_to == sent_to
      assert auth_token.expires_at == expires_at
    end
  end

  describe "expired?/1" do
    test "returns true for expired token" do
      expires_at = DateTime.utc_now() |> DateTime.add(-3600, :second)
      auth_token = AuthToken.new("token", "magic_link", "test@example.com", expires_at)

      assert AuthToken.expired?(auth_token) == true
    end

    test "returns false for valid token" do
      expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)
      auth_token = AuthToken.new("token", "magic_link", "test@example.com", expires_at)

      assert AuthToken.expired?(auth_token) == false
    end
  end

  describe "valid_context?/1" do
    test "returns true for valid context" do
      assert AuthToken.valid_context?("magic_link") == true
      assert AuthToken.valid_context?("password_reset") == true
      assert AuthToken.valid_context?("email_confirmation") == true
    end

    test "returns false for invalid context" do
      assert AuthToken.valid_context?("invalid_context") == false
      assert AuthToken.valid_context?("") == false
      assert AuthToken.valid_context?(nil) == false
    end
  end
end
