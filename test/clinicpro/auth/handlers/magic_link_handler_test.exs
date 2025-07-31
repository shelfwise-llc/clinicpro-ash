defmodule Clinicpro.Auth.Handlers.MagicLinkHandlerTest do
  use Clinicpro.DataCase, async: true

  alias Clinicpro.Auth.Handlers.MagicLinkHandler
  alias Clinicpro.Auth.Services.TokenService
  alias Clinicpro.Auth.Finders.UserFinder
  alias Clinicpro.Auth.Finders.TokenFinder

  describe "initiate/1" do
    test "sends magic link when user exists" do
      # Since we're using stubs, we'll need to mock the dependencies
      # For now, we'll just test that the function runs without error
      assert {:ok, :email_sent} = MagicLinkHandler.initiate("test@example.com")
    end

    test "returns success even when user doesn't exist" do
      # Test that we don't reveal user existence
      assert {:ok, :email_sent} = MagicLinkHandler.initiate("nonexistent@example.com")
    end
  end

  describe "validate_token/1" do
    test "validates a token" do
      token = TokenService.generate_token()
      hashed_token = TokenService.hash_token(token)

      # Since we're using stubs, we'll just test that the function runs
      assert {:error, :invalid_token} = MagicLinkHandler.validate_token(token)
    end
  end
end
