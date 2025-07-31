defmodule Clinicpro.Auth.Handlers.MagicLinkHandler do
  @moduledoc """
  Handler for processing magic link authentication requests.

  This module is responsible for generating tokens, sending magic link emails,
  and validating authentication requests.
  """

  alias Clinicpro.Auth.Services.TokenService
  alias Clinicpro.Auth.Finders.UserFinder
  alias Clinicpro.Email.Services.EmailService
  alias Clinicpro.Auth.Values.AuthToken

  @token_length 32
  @token_context "magic_link"

  @doc """
  Initiates the magic link authentication process for a user with the given email.
  """
  def initiate(email) when is_binary(email) do
    case UserFinder.by_email(email) do
      {:ok, user} ->
        token = TokenService.generate_token(@token_length)
        hashed_token = TokenService.hash_token(token)

        case TokenService.persist_token(user.id, hashed_token, @token_context, email) do
          :ok ->
            # Send the magic link email using our new email service
            EmailService.send_magic_link(user, token)
            {:ok, :email_sent}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        # For security, we don't reveal whether the email exists
        {:ok, :email_sent}
    end
  end

  @doc """
  Validates a magic link token and returns the associated user if valid.
  """
  def validate(token) when is_binary(token) do
    hashed_token = TokenService.hash_token(token)

    case TokenService.validate_token(hashed_token, @token_context) do
      {:ok, user_id} ->
        case UserFinder.by_id(user_id) do
          {:ok, user} ->
            {:ok, user}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
