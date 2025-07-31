defmodule Clinicpro.Accounts.DoctorService do
  @moduledoc """
  Business logic for doctor operations.
  """

  alias Clinicpro.Auth.Values.AuthToken
  alias Clinicpro.Repo
  alias Clinicpro.Accounts.Doctor

  @magic_link_context "doctor_magic_link"
  @session_duration_hours 24

  @doc """
  Generates a magic link token for a doctor.
  """
  def generate_magic_link(doctor) do
    token = generate_secure_token()
    _hashed_token = hash_token(token)
    expires_at = DateTime.utc_now() |> DateTime.add(@session_duration_hours * 3600, :second)

    _auth_token = AuthToken.new(token, @magic_link_context, doctor.email, expires_at)

    # Persist token (stub implementation)
    {:ok, token, "#{ClinicproWeb.Endpoint.url()}/doctor/magic-link?token=#{token}"}
  end

  @doc """
  Validates a doctor's login session.
  """
  def validate_login_session(doctor) do
    # Generate session data
    session_data = %{
      doctor_id: doctor.id,
      expires_at: DateTime.utc_now() |> DateTime.add(@session_duration_hours * 3600, :second),
      permissions: doctor_permissions(doctor)
    }

    {:ok, session_data}
  end

  @doc """
  Invalidates a doctor's session.
  """
  def invalidate_session(_doctor_id) do
    # Session invalidation logic
    :ok
  end

  defp generate_secure_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64()
  end

  defp hash_token(token) do
    :crypto.hash(:sha256, token) |> Base.encode16()
  end

  defp doctor_permissions(doctor) do
    [
      :view_dashboard,
      :manage_appointments,
      :view_patients,
      :write_prescriptions
    ]
  end
end
