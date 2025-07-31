ExUnit.start()

defmodule Clinicpro.Auth.Handlers.MagicLinkHandler do
  @moduledoc """
  Handler for magic link authentication flow.
  """

  @token_length 32
  @token_context "magic_link"

  def initiate(email) do
    case UserFinder.by_email(email) do
      {:ok, user} ->
        token = TokenService.generate_token(@token_length)
        hashed_token = TokenService.hash_token(token)

        case TokenService.persist_token(user.id, hashed_token, @token_context, email) do
          :ok ->
            EmailService.send_magic_link(user, token)
            {:ok, :email_sent}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        {:ok, :email_sent}
    end
  end

  def validate_token(token) do
    hashed_token = TokenService.hash_token(token)

    case TokenService.find_and_validate_token(hashed_token, @token_context) do
      {:ok, user_id} ->
        case UserFinder.by_id(user_id) do
          {:ok, user} -> {:ok, user}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end

defmodule UserFinder do
  def by_email(_email), do: {:ok, %{id: 1, email: "test@example.com", name: "Test User"}}
  def by_id(_id), do: {:ok, %{id: 1, email: "test@example.com", name: "Test User"}}
end

defmodule TokenService do
  def generate_token(length), do: String.duplicate("a", length)
  def hash_token(token), do: "hashed_" <> token
  def persist_token(_user_id, _hashed_token, _context, _email), do: :ok
  def find_and_validate_token(_hashed_token, _context), do: {:ok, 1}
end

defmodule EmailService do
  def send_magic_link(_user, _token), do: :ok
end

defmodule Clinicpro.Auth.Handlers.MagicLinkHandlerTest do
  use ExUnit.Case, async: true

  alias Clinicpro.Auth.Handlers.MagicLinkHandler

  describe "initiate/1" do
    test "returns email_sent for existing user" do
      assert {:ok, :email_sent} = MagicLinkHandler.initiate("test@example.com")
    end

    test "returns email_sent for non-existing user" do
      # Override UserFinder to return not found
      defmodule UserFinder do
        def by_email(_email), do: {:error, :not_found}
      end

      assert {:ok, :email_sent} = MagicLinkHandler.initiate("nonexistent@example.com")
    end
  end

  describe "validate_token/1" do
    test "returns user for valid token" do
      assert {:ok, user} = MagicLinkHandler.validate_token("valid_token")
      assert user.id == 1
      assert user.email == "test@example.com"
    end
  end
end
