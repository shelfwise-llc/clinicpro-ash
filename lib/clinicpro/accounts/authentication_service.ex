defmodule Clinicpro.Accounts.AuthenticationService do
  @moduledoc """
  SRP-compliant authentication service handling all portal authentication.
  Single responsibility: authentication logic only.
  """

  alias Clinicpro.Accounts.{Patient, Doctor, Admin}
  alias Clinicpro.Repo
  alias Clinicpro.Auth.OTP

  @doc "Patient OTP authentication"
  def authenticate_patient(phone, clinic_id) do
    case Repo.get_by(Patient, phone: phone, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      patient -> {:ok, patient}
    end
  end

  @doc "Doctor password authentication"
  def authenticate_doctor(email, password, clinic_id) do
    case Repo.get_by(Doctor, email: email, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      doctor -> verify_password(doctor, password)
    end
  end

  @doc "Admin authentication"
  def authenticate_admin(email, password, clinic_id) do
    case Repo.get_by(Admin, email: email, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      admin -> verify_password(admin, password)
    end
  end

  @doc "Generate OTP for patient"
  def generate_patient_otp(patient) do
    otp = OTP.generate()
    expiry = DateTime.add(DateTime.utc_now(), 300) # 5 minutes
    
    {:ok, otp, expiry}
  end

  @doc "Verify OTP"
  def verify_otp(otp, expected_otp) do
    OTP.verify(otp, expected_otp)
  end

  defp verify_password(user, password) do
    case user.password_hash do
      nil -> {:error, :no_password}
      hash -> 
        if Bcrypt.verify_pass(password, hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end
end
