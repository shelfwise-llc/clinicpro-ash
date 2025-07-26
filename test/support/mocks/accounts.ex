defmodule Clinicpro.Mocks.Accounts do
  @moduledoc """
  Mock implementation of the Accounts API for tests.
  This completely bypasses the Ash resources to avoid compilation issues.
  """

  # Define structs locally to avoid compilation order issues
  defmodule MockUser do
    defstruct [:id, :email, :role, :doctor, :patient, :admin]
  end

  defmodule MockDoctor do
    defstruct [:id, :first_name, :last_name, :specialty, :clinic_id]
  end

  defmodule MockPatient do
    defstruct [:id, :first_name, :last_name, :date_of_birth]
  end

  # User management functions
  def get_user(id) do
    {:ok,
     %MockUser{
       id: id,
       email: "user-#{id}@example.com",
       role: :patient
     }}
  end

  def get_user_by_email(email) do
    {:ok,
     %MockUser{
       id: "user-#{:erlang.phash2(email)}",
       email: email,
       role: :patient
     }}
  end

  def create_user(attrs) do
    {:ok,
     %MockUser{
       id: Ecto.UUID.generate(),
       email: attrs[:email],
       role: attrs[:role] || :patient
     }}
  end

  # Authentication functions
  def sign_in(conn, user) do
    Plug.Conn.put_session(conn, :current_user, user)
  end

  def sign_out(conn) do
    Plug.Conn.delete_session(conn, :current_user)
  end

  def current_user(conn) do
    Plug.Conn.get_session(conn, :current_user)
  end

  def signed_in?(conn) do
    !!current_user(conn)
  end

  # Magic link authentication
  def generate_magic_link_token(email) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    Process.put({:magic_link_token, email}, token)
    token
  end

  def verify_magic_link_token(token) do
    # Find the email associated with this token
    email = Process.get({:magic_link_token, token})

    if email do
      {:ok, %MockUser{id: Ecto.UUID.generate(), email: email, role: :patient}}
    else
      {:error, :invalid_token}
    end
  end

  def authenticate_by_magic_link(token) do
    verify_magic_link_token(token)
  end

  def send_magic_link(email) do
    token = generate_magic_link_token(email)
    {:ok, token}
  end
end
