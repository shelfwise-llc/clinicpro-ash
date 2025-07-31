defmodule Clinicpro.Accounts.AdminService do
  @moduledoc """
  Business logic for admin operations.
  """

  alias Clinicpro.Auth.Values.AuthToken
  alias Clinicpro.Repo
  alias Clinicpro.Accounts.Admin

  @magic_link_context "admin_magic_link"
  @session_duration_hours 24

  @doc """
  Generates a magic link token for an admin.
  """
  def generate_magic_link(admin) do
    token = generate_secure_token()
    _hashed_token = hash_token(token)
    expires_at = DateTime.utc_now() |> DateTime.add(@session_duration_hours * 3600, :second)

    _auth_token = AuthToken.new(token, @magic_link_context, admin.email, expires_at)

    # Persist token (stub implementation)
    {:ok, token, "#{ClinicproWeb.Endpoint.url()}/admin/magic-link?token=#{token}"}
  end

  @doc """
  Validates an admin's login session.
  """
  def validate_login_session(admin) do
    # Generate session data
    session_data = %{
      admin_id: admin.id,
      expires_at: DateTime.utc_now() |> DateTime.add(@session_duration_hours * 3600, :second),
      permissions: admin_permissions(admin)
    }

    {:ok, session_data}
  end

  @doc """
  Invalidates an admin's session.
  """
  def invalidate_session(_admin_id) do
    # Session invalidation logic
    :ok
  end

  defp generate_secure_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64()
  end

  defp hash_token(token) do
    :crypto.hash(:sha256, token) |> Base.encode16()
  end

  defp admin_permissions(admin) do
    [
      :view_dashboard,
      :manage_clinics,
      :manage_doctors,
      :manage_patients,
      :view_analytics,
      :manage_settings
    ]
  end
end
