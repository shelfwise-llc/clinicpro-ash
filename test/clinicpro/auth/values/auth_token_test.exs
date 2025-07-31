defmodule Clinicpro.Auth.Values.AuthTokenTest do
  use Clinicpro.DataCase, async: true

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
      auth_token = AuthToken.new("token", "context", "email", expires_at)

      assert AuthToken.expired?(auth_token)
    end

    test "returns false for valid token" do
      expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)
      auth_token = AuthToken.new("token", "context", "email", expires_at)

      refute AuthToken.expired?(auth_token)
    end
  end

  describe "valid_context?/1" do
    test "returns true for valid context" do
      assert AuthToken.valid_context?("magic_link")
      assert AuthToken.valid_context?("password_reset")
    end

    test "returns false for invalid context" do
      refute AuthToken.valid_context?("")
      refute AuthToken.valid_context?(nil)
    end
  end
end
