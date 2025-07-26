defmodule Clinicpro.Accounts do
  @moduledoc """
  Accounts API for ClinicPro.
  """
  # Temporarily removed AshAuthentication extension
  use Ash.Api

  resources do
    resource(Clinicpro.Accounts.User)
    resource(Clinicpro.Accounts.Role)
    resource(Clinicpro.Accounts.Permission)
    resource(Clinicpro.Accounts.UserRole)
    resource(Clinicpro.Accounts.Token)
  end

  # Temporarily comment out authentication to bypass AshAuthentication issues
  # authentication do
  #   subject_name :user
  #   strategies do
  #     magic_link :magic_link do
  #       identity_field :email
  #       sender Clinicpro.Accounts.MagicLinkSender
  #     end
  #   end
  #   
  #   tokens do
  #     enabled? true
  #     token_resource Clinicpro.Accounts.Token
  #     signing_secret fn _unused, _unused -> Application.fetch_env!(:clinicpro, :token_signing_secret) end
  #     token_lifetime 60 * 60 * 24 * 7 # 7 days
  #   end
  # end

  authorization do
    authorize(:by_default)
  end

  # Authentication configuration commented out for development
  # We're using the AuthPlaceholder module instead
  #
  # authentication do
  #   strategies do
  #     magic_link :magic_link do
  #       identity_field(:email)
  #       sender(Clinicpro.Accounts.MagicLinkSender)
  #       sign_in_tokens_enabled?(true)
  #
  #       token_signing_secret(fn ->
  #         "very_long_secret_that_is_used_for_signing_tokens_in_development"
  #       end)
  #     end
  #   end
  #
  #   tokens do
  #     enabled?(true)
  #     
  #     signing_secret(fn _unused, _unused ->
  #       "some_dev_secret_at_least_64_bytes_long_to_secure_the_authentication_tokens"
  #     end)
  #   end
  # end

  # Placeholder authentication functions for development and testing
  # These delegate to our placeholder module while we resolve AshAuthentication issues

  @doc """
  Generate a token for a user.

  ## Examples

      iex> generate_token_for_user(user_id)
      {:ok, %Token{...}}

  """
  defdelegate generate_token_for_user(user_id), to: Clinicpro.Accounts.AuthPlaceholder

  @doc """
  Request a magic link for a user.

  ## Examples

      iex> request_magic_link(%{email: "user@example.com"})
      {:ok, %{success: true}}

  """
  def request_magic_link(%{email: email}) do
    # In development, just log the email
    IO.puts("Magic link requested for: #{email}")
    {:ok, %{success: true}}
  end

  @doc """
  Authenticate a user by their email (placeholder for magic link authentication).

  ## Examples

      iex> authenticate_by_email("user@example.com")
      {:ok, %Token{...}}

  """
  defdelegate authenticate_by_email(email), to: Clinicpro.Accounts.AuthPlaceholder

  @doc """
  Authenticate a user by their credentials.

  ## Examples

      iex> authenticate_by_credentials("user@example.com", "password")
      {:ok, %Token{...}}

  """
  defdelegate authenticate_by_credentials(email, password), to: Clinicpro.Accounts.AuthPlaceholder

  @doc """
  Verify a token is valid.

  ## Examples

      iex> verify_token("token_string")
      {:ok, %Token{...}}

  """
  defdelegate verify_token(token), to: Clinicpro.Accounts.AuthPlaceholder
end
