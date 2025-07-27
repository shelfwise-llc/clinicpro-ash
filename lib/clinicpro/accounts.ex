defmodule Clinicpro.Accounts do
  @moduledoc """
  The Accounts context.

  This module handles user authentication, registration, and session management
  with multi-tenant support via clinic_id.
  """

  import Ecto.Query, warn: false
  alias Clinicpro.Repo
  alias Clinicpro.Accounts.{AuthUser, AuthUserToken}
  alias Clinicpro.Email

  ## Database getters

  @doc """
  Gets a auth_user by email.
  """
  def get_auth_user_by_email(email) when is_binary(email) do
    Repo.get_by(AuthUser, email: email)
  end

  @doc """
  Gets a auth_user by email and clinic_id.

  This enforces multi-tenant isolation by ensuring users can only
  be found within their assigned clinic.
  """
  def get_auth_user_by_email_and_clinic(email, clinic_id) when is_binary(email) do
    Repo.get_by(AuthUser, email: email, clinic_id: clinic_id)
  end

  @doc """
  Gets a auth_user by ID.
  """
  def get_auth_user(id), do: Repo.get(AuthUser, id)

  @doc """
  Gets a auth_user by ID, raising an error if not found.
  """
  def get_auth_user!(id), do: Repo.get!(AuthUser, id)

  ## User registration

  @doc """
  Registers a auth_user.

  ## Examples

      iex> register_auth_user(%{field: value})
      {:ok, %AuthUser{}}

      iex> register_auth_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_auth_user(attrs) do
    %AuthUser{}
    |> AuthUser.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking auth_user changes.

  ## Examples

      iex> change_auth_user_registration(auth_user)
      %Ecto.Changeset{data: %AuthUser{}}

  """
  def change_auth_user_registration(%AuthUser{} = auth_user, attrs \\ %{}) do
    AuthUser.registration_changeset(auth_user, attrs)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the auth_user email.

  ## Examples

      iex> change_auth_user_email(auth_user)
      %Ecto.Changeset{data: %AuthUser{}}

  """
  def change_auth_user_email(auth_user, attrs \\ %{}) do
    AuthUser.email_changeset(auth_user, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the auth_user password.

  ## Examples

      iex> change_auth_user_password(auth_user)
      %Ecto.Changeset{data: %AuthUser{}}

  """
  def change_auth_user_password(auth_user, attrs \\ %{}) do
    AuthUser.password_changeset(auth_user, attrs)
  end

  @doc """
  Updates the auth_user password.

  ## Examples

      iex> update_auth_user_password(auth_user, "valid password", %{password: ...})
      {:ok, %AuthUser{}}

      iex> update_auth_user_password(auth_user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_auth_user_password(auth_user, current_password, attrs) do
    changeset =
      auth_user
      |> AuthUser.password_changeset(attrs)
      |> AuthUser.validate_current_password(current_password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:auth_user, changeset)
    |> Ecto.Multi.delete_all(:tokens, AuthUserToken.user_and_contexts_query(auth_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{auth_user: auth_user}} -> {:ok, auth_user}
      {:error, :auth_user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_auth_user_session_token(auth_user) do
    {token, auth_user_token} = AuthUserToken.build_session_token(auth_user)
    Repo.insert!(auth_user_token)
    token
  end

  @doc """
  Gets the auth_user with the given signed token.
  """
  def get_auth_user_by_session_token(token) do
    {:ok, query} = AuthUserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_auth_user_session_token(token) do
    Repo.delete_all(AuthUserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Authentication

  @doc """
  Authenticates a auth_user by email and password.

  ## Examples

      iex> authenticate_auth_user_by_email_password("user@example.com", "correct_password")
      {:ok, %AuthUser{}}

      iex> authenticate_auth_user_by_email_password("user@example.com", "invalid_password")
      {:error, :invalid_credentials}

  """
  def authenticate_auth_user_by_email_password(email, password) do
    auth_user = get_auth_user_by_email(email)
    authenticate_auth_user(auth_user, password)
  end

  @doc """
  Authenticates a auth_user by email, password, and clinic_id.

  This enforces multi-tenant isolation by ensuring users can only
  authenticate within their assigned clinic.

  ## Examples

      iex> authenticate_auth_user_by_email_password_and_clinic("user@example.com", "correct_password", "clinic_id")
      {:ok, %AuthUser{}}

      iex> authenticate_auth_user_by_email_password_and_clinic("user@example.com", "invalid_password", "clinic_id")
      {:error, :invalid_credentials}

  """
  def authenticate_auth_user_by_email_password_and_clinic(email, password, clinic_id) do
    auth_user = get_auth_user_by_email_and_clinic(email, clinic_id)
    authenticate_auth_user(auth_user, password)
  end

  defp authenticate_auth_user(auth_user, password) do
    if auth_user && AuthUser.valid_password?(auth_user, password) do
      {:ok, auth_user}
    else
      {:error, :invalid_credentials}
    end
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given auth_user.

  ## Examples

      iex> deliver_auth_user_reset_password_instructions(auth_user, &url_fun/1)
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_auth_user_reset_password_instructions(%AuthUser{} = auth_user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, auth_user_token} = AuthUserToken.build_email_token(auth_user, "reset_password")
    Repo.insert!(auth_user_token)
    Email.deliver_reset_password_instructions(auth_user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the auth_user by reset password token.

  ## Examples

      iex> get_auth_user_by_reset_password_token("validtoken")
      %AuthUser{}

      iex> get_auth_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_auth_user_by_reset_password_token(token) do
    with {:ok, query} <- AuthUserToken.verify_email_token_query(token, "reset_password"),
         %AuthUser{} = auth_user <- Repo.one(query) do
      auth_user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the auth_user password.

  ## Examples

      iex> reset_auth_user_password(auth_user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %AuthUser{}}

      iex> reset_auth_user_password(auth_user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_auth_user_password(auth_user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:auth_user, AuthUser.password_changeset(auth_user, attrs))
    |> Ecto.Multi.delete_all(:tokens, AuthUserToken.user_and_contexts_query(auth_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{auth_user: auth_user}} -> {:ok, auth_user}
      {:error, :auth_user, changeset, _} -> {:error, changeset}
    end
  end
end
