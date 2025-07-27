defmodule Clinicpro.Auth.OTP do
  @moduledoc """
  Handles OTP (One-Time Password) generation and validation for patient authentication.
  Supports multi-tenant architecture where each clinic can have its own _patients with OTPs.
  """

  alias Clinicpro.Auth.OTPSecret
  alias Clinicpro.Auth.OTPDelivery
  alias Clinicpro.Repo
  alias Clinicpro.Patient
  alias Clinicpro.Clinic

  # OTP validity period in seconds (30 seconds is standard for TOTP)
  @otp_validity_period 30
  # Number of periods to check before and after current time (to account for clock skew)
  @allowed_drift 1

  @doc """
  Generates a new OTP for a patient in a specific clinic.
  Returns a tuple with the OTP and the secret.
  """
  def generate_otp(patient_id, clinic_identifier) do
    # First check if the patient exists and is valid
    with {:ok, _patient} <- get_patient(patient_id) do
      # Deactivate any existing OTP secrets for this patient in this clinic
      OTPSecret.deactivate_for_patient(patient_id, clinic_identifier)

      # Generate a new OTP secret
      case OTPSecret.generate_for_patient(patient_id, clinic_identifier) do
        {:ok, otp_secret} ->
          # Generate the current OTP using NimbleTOTP
          otp = NimbleTOTP.verification_code(otp_secret.secret)
          {:ok, %{otp: otp, secret: otp_secret}}

        error ->
          error
      end
    end
  end

  @doc """
  Validates an OTP for a patient in a specific clinic.
  Returns :ok if valid, {:error, reason} otherwise.
  """
  def validate_otp(patient_id, clinic_identifier, otp) do
    # Find active OTP secret for this patient in this clinic
    case OTPSecret.find_active_for_patient(patient_id, clinic_identifier) do
      nil ->
        {:error, :no_active_secret}

      otp_secret ->
        # Validate the OTP using NimbleTOTP
        if NimbleTOTP.valid?(otp, otp_secret.secret,
             time: System.system_time(:second),
             window: @allowed_drift,
             period: @otp_validity_period
           ) do
          # Mark the OTP secret as used
          OTPSecret.mark_as_used(otp_secret.id)
          {:ok, otp_secret}
        else
          {:error, :invalid_otp}
        end
    end
  end

  @doc """
  Generates a QR code URL for setting up OTP in authenticator apps.
  """
  def generate_qr_code_url(patient_id, clinic_identifier) do
    with {:ok, patient} <- get_patient(patient_id),
         otp_secret when not is_nil(otp_secret) <-
           OTPSecret.find_active_for_patient(patient_id, clinic_identifier) do
      # Create a provisioning URI for authenticator apps
      issuer = "ClinicPro-#{clinic_identifier}"
      account = "#{patient.email || patient.phone_number}"

      NimbleTOTP.otpauth_uri(issuer, account, otp_secret.secret, period: @otp_validity_period)
    else
      nil -> {:error, :no_active_secret}
      error -> error
    end
  end

  @doc """
  Sends an OTP to a patient via SMS or email using the OTPDelivery module.
  Returns {:ok, %{otp: otp, contact: contact}} on success or {:error, reason} on failure.
  """
  def send_otp(patient_id, clinic_identifier) do
    case generate_otp(patient_id, clinic_identifier) do
      {:ok, %{otp: otp, secret: _secret}} ->
        # Use the OTPDelivery module to send the OTP
        case OTPDelivery.send_otp(patient_id, clinic_identifier, otp) do
          {:ok, %{method: method, contact: contact}} ->
            # Return the OTP and contact info for development purposes
            # In production, you would not expose the OTP in the response
            {:ok, %{otp: otp, contact: contact, method: method}}

          error ->
            error
        end

      error ->
        error
    end
  end

  # Private helper functions

  defp get_patient(patient_id) do
    case Repo.get(Patient, patient_id) do
      nil -> {:error, :patient_not_found}
      patient -> {:ok, patient}
    end
  end

  # No longer need the get_clinic function since we're using clinic_identifier string
end
