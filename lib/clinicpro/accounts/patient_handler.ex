defmodule Clinicpro.Accounts.PatientHandler do
  @moduledoc """
  Handles patient-related business logic and orchestration.
  """

  alias Clinicpro.Accounts.{PatientService, PatientFinder}

  @doc """
  Handles patient login with magic link validation.
  """
  def handle_magic_link_login(token, clinic_id) do
    case PatientFinder.find_by_magic_link_token(token, clinic_id) do
      {:ok, patient} ->
        case PatientService.validate_login_session(patient) do
          {:ok, session_data} ->
            {:ok, patient, session_data}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Initiates magic link for patient login.
  """
  def initiate_magic_link(email, clinic_id) do
    case PatientFinder.find_by_email(email, clinic_id) do
      {:ok, patient} ->
        case PatientService.generate_magic_link(patient) do
          {:ok, token, magic_link} ->
            {:ok, patient, token, magic_link}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        # Don't reveal user existence
        {:ok, :email_sent}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Handles patient registration.
  """
  def register_patient(attrs) do
    case PatientService.create_patient(attrs) do
      {:ok, patient} ->
        case PatientService.generate_magic_link(patient) do
          {:ok, _token, _magic_link} ->
            {:ok, patient}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Handles patient logout.
  """
  def logout(patient_id) do
    PatientService.invalidate_session(patient_id)
  end
end
