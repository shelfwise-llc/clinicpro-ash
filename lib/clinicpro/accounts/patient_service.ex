defmodule Clinicpro.Accounts.PatientService do
  @moduledoc """
  Service module for handling patient-related business logic.
  """

  alias Clinicpro.Auth.Values.AuthToken

  @magic_link_context "patient_magic_link"
  @session_duration_hours 24

  @doc """
  Generates a magic link token for a patient.
  """
  def generate_magic_link(patient) do
    token = generate_secure_token()
    _hashed_token = hash_token(token)
    expires_at = DateTime.utc_now() |> DateTime.add(@session_duration_hours * 3600, :second)

    _auth_token = AuthToken.new(token, @magic_link_context, patient.email, expires_at)

    # Persist token (stub implementation)
    {:ok, token, "#{ClinicproWeb.Endpoint.url()}/patient/magic-link?token=#{token}"}
  end

  @doc """
  Creates a new patient.
  """
  def create_patient(attrs) do
    # Patient creation logic (stub)
    patient = %{
      id: 1,
      name: attrs[:name] || attrs["name"],
      email: attrs[:email] || attrs["email"],
      phone: attrs[:phone] || attrs["phone"]
    }

    {:ok, patient}
  end

  @doc """
  Validates a patient's login session.
  """
  def validate_login_session(_patient) do
    # Stub implementation
    {:ok, %{authenticated: true}}
  end

  @doc """
  Invalidates a patient's session.
  """
  def invalidate_session(_patient_id) do
    # Session invalidation logic
    :ok
  end

  defp generate_secure_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64()
  end

  defp hash_token(token) do
    :crypto.hash(:sha256, token) |> Base.encode16()
  end

  defp patient_permissions(patient) do
    [
      :view_dashboard,
      :book_appointments,
      :view_prescriptions,
      :view_medical_records
    ]
  end
end
