defmodule ClinicproWeb.PatientAuthController do
  use ClinicproWeb, :controller

  alias Clinicpro.Auth.OTP
  alias Clinicpro.Patient
  # # alias Clinicpro.Repo

  @doc """
  Renders the form to request an OTP.
  """
  def request_otp(conn, %{"_clinic_id" => _clinic_id}) do
    changeset = Patient.changeset(%Patient{}, %{})
    render(conn, :request_otp, changeset: changeset, _clinic_id: _clinic_id)
  end

  @doc """
  Processes the OTP request form and sends an OTP to the patient.
  """
  def send_otp(conn, %{"patient" => patient_params, "_clinic_id" => _clinic_id}) do
    # First, try to find the patient by phone number or email
    patient = find_or_create_patient(patient_params, _clinic_id)

    case OTP.send_otp(patient.id, _clinic_id) do
      {:ok, %{otp: otp, contact: contact}} ->
        # In production, you would not expose the OTP in the session
        # This is just for development convenience
        conn
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otp_clinic_id, _clinic_id)
        |> put_flash(:info, "OTP sent to #{contact}. For development: #{otp}")
        |> redirect(to: ~p"/patient/verify-otp?_clinic_id=#{_clinic_id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to send OTP: #{inspect(reason)}")
        |> redirect(to: ~p"/patient/request-otp?_clinic_id=#{_clinic_id}")
    end
  end

  @doc """
  Renders the form to verify an OTP.
  """
  def verify_otp_form(conn, %{"_clinic_id" => _clinic_id}) do
    case get_session(conn, :pending_otp_patient_id) do
      nil ->
        conn
        |> put_flash(:error, "Please request an OTP first")
        |> redirect(to: ~p"/patient/request-otp?_clinic_id=#{_clinic_id}")

      _patient_id ->
        render(conn, :verify_otp, _clinic_id: _clinic_id)
    end
  end

  @doc """
  Verifies the submitted OTP and authenticates the patient if valid.
  """
  def verify_otp(conn, %{"otp" => otp, "_clinic_id" => _clinic_id}) do
    patient_id = get_session(conn, :pending_otp_patient_id)
    _clinic_id = get_session(conn, :pending_otp_clinic_id)

    case OTP.validate_otp(patient_id, _clinic_id, otp) do
      {:ok, _otp_secret} ->
        # Fetch the patient to get their details
        patient = Repo.get(Patient, patient_id)

        conn
        |> delete_session(:pending_otp_patient_id)
        |> delete_session(:pending_otp_clinic_id)
        |> put_session(:patient_id, patient_id)
        |> put_session(:_clinic_id, _clinic_id)
        |> put_flash(:info, "Successfully authenticated. Welcome #{patient.first_name || "Patient"}!")
        |> redirect(to: ~p"/patient/dashboard")

      {:error, :invalid_otp} ->
        conn
        |> put_flash(:error, "Invalid OTP. Please try again.")
        |> redirect(to: ~p"/patient/verify-otp?_clinic_id=#{_clinic_id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/patient/request-otp?_clinic_id=#{_clinic_id}")
    end
  end

  @doc """
  Renders the patient dashboard after successful authentication.
  """
  def dashboard(conn, _params) do
    case get_session(conn, :patient_id) do
      nil ->
        conn
        |> put_flash(:error, "Please log in to access the dashboard")
        |> redirect(to: ~p"/")

      patient_id ->
        _clinic_id = get_session(conn, :_clinic_id)
        patient = Repo.get(Patient, patient_id)

        # Here you would fetch real data for the dashboard
        # For now, we'll just render the template with the patient
        render(conn, :dashboard, patient: patient, _clinic_id: _clinic_id)
    end
  end

  @doc """
  Logs out the patient by clearing the session.
  """
  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: ~p"/")
  end

  # Private helper functions

  defp find_or_create_patient(params, _clinic_id) do
    # Try to find by phone number first, then by email
    patient =
      cond do
        params["phone_number"] && params["phone_number"] != "" ->
          Repo.get_by(Patient, phone_number: params["phone_number"], _clinic_id: _clinic_id)

        params["email"] && params["email"] != "" ->
          Repo.get_by(Patient, email: params["email"], _clinic_id: _clinic_id)

        true -> nil
      end

    # If patient not found, create a new one
    if patient do
      patient
    else
      # Add _clinic_id to params
      params_with_clinic = Map.put(params, "_clinic_id", _clinic_id)

      {:ok, new_patient} =
        %Patient{}
        |> Patient.changeset(params_with_clinic)
        |> Repo.insert()

      new_patient
    end
  end
end
