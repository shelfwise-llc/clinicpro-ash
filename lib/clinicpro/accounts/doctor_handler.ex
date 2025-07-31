defmodule Clinicpro.Accounts.DoctorHandler do
  @moduledoc """
  Handles doctor-related business logic and orchestration.
  """

  alias Clinicpro.Accounts.{DoctorService, DoctorFinder}

  @doc """
  Handles doctor login with magic link validation.
  """
  def handle_magic_link_login(token, clinic_id) do
    case DoctorFinder.find_by_magic_link_token(token, clinic_id) do
      {:ok, doctor} ->
        case DoctorService.validate_login_session(doctor) do
          {:ok, session_data} ->
            {:ok, doctor, session_data}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        {:error, :invalid_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Initiates magic link for doctor login.
  """
  def initiate_magic_link(email, clinic_id) do
    case DoctorFinder.find_by_email(email, clinic_id) do
      {:ok, doctor} ->
        case DoctorService.generate_magic_link(doctor) do
          {:ok, token, magic_link} ->
            {:ok, doctor, token, magic_link}

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
  Handles doctor logout.
  """
  def logout(doctor_id) do
    DoctorService.invalidate_session(doctor_id)
  end
end
