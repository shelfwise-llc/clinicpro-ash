defmodule ClinicproWeb.PatientAuthController do
  use ClinicproWeb, :controller

  alias Clinicpro.Auth.OTP
  alias Clinicpro.Patient
  # # alias Clinicpro.Repo

  @doc """
  Renders the form to request an OTP.
  """
  def request_otp(conn, %{"clinic_id" => clinic_id}) do
    changeset = Patient.changeset(%Patient{}, %{})

    conn
    |> put_layout(html: :root)
    |> render("request_otp.html", changeset: changeset, clinic_id: clinic_id)
  end

  @doc """
  Renders the form to request an OTP without a clinic_id.
  """
  def request_otp(conn, _params) do
    # Default to clinic_id 1 or fetch from config if available
    clinic_id = Application.get_env(:clinicpro, :default_clinic_id, "1")
    changeset = Patient.changeset(%Patient{}, %{})

    conn
    |> put_layout(html: :root)
    |> render("request_otp.html", changeset: changeset, clinic_id: clinic_id)
  end

  @doc """
  Processes the OTP request form and sends an OTP to the patient with clinic_id.
  """
  def send_otp(conn, %{"patient" => patient_params, "clinic_id" => clinic_id}) do
    # First, try to find the patient by phone number or email
    patient = find_or_create_patient(patient_params, clinic_id)

    case OTP.send_otp(patient.id, clinic_id) do
      {:ok, %{otp: otp, contact: contact}} ->
        # In production, you would not expose the OTP in the session
        # This is just for development convenience
        conn
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otpclinic_id, clinic_id)
        |> put_flash(:info, "OTP sent to #{contact}. For development: #{otp}")
        |> redirect(to: ~p"/patient/verify-otp?clinic_id=#{clinic_id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to send OTP: #{inspect(reason)}")
        |> redirect(to: ~p"/patient/request-otp?clinic_id=#{clinic_id}")
    end
  end

  @doc """
  Processes the OTP request form and sends an OTP to the patient without clinic_id.
  """
  def send_otp(conn, %{"patient" => patient_params}) do
    # Default to clinic_id 1 or fetch from config if available
    clinic_id = Application.get_env(:clinicpro, :default_clinic_id, "1")
    # First, try to find the patient by phone number or email
    patient = find_or_create_patient(patient_params, clinic_id)

    case OTP.send_otp(patient.id, clinic_id) do
      {:ok, %{otp: otp, contact: contact}} ->
        # In production, you would not expose the OTP in the session
        # This is just for development convenience
        conn
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otpclinic_id, clinic_id)
        |> put_flash(:info, "OTP sent to #{contact}. For development: #{otp}")
        |> redirect(to: ~p"/patient/verify-otp")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to send OTP: #{inspect(reason)}")
        |> redirect(to: ~p"/patient/request-otp")
    end
  end

  @doc """
  Renders the form to verify an OTP.
  """
  def verify_otp_form(conn, %{"clinic_id" => clinic_id}) do
    case get_session(conn, :pending_otp_patient_id) do
      nil ->
        conn
        |> put_flash(:error, "Please request an OTP first")
        |> redirect(to: ~p"/patient/request-otp?clinic_id=#{clinic_id}")

      _patient_id ->
        conn
        |> put_layout(html: :root)
        |> render("verify_otp.html", clinic_id: clinic_id)
    end
  end

  @doc """
  Renders the form to verify an OTP without a clinic_id.
  """
  def verify_otp_form(conn, _params) do
    case get_session(conn, :pending_otp_patient_id) do
      nil ->
        conn
        |> put_flash(:error, "Please request an OTP first")
        |> redirect(to: ~p"/patient/request-otp")

      _patient_id ->
        # Get the clinic_id from the session or use default
        clinic_id =
          get_session(conn, :pending_otpclinic_id) ||
            Application.get_env(:clinicpro, :default_clinic_id, "1")

        conn
        |> put_layout(html: :root)
        |> render("verify_otp.html", clinic_id: clinic_id)
    end
  end

  @doc """
  Verifies the submitted OTP and authenticates the patient if valid.
  """
  def verify_otp(conn, %{"otp" => otp, "clinic_id" => clinic_id}) do
    patient_id = get_session(conn, :pending_otp_patient_id)
    clinic_id = get_session(conn, :pending_otpclinic_id)

    case OTP.validate_otp(patient_id, clinic_id, otp) do
      {:ok, _otp_secret} ->
        # Fetch the patient to get their details
        patient = Repo.get(Patient, patient_id)

        conn
        |> delete_session(:pending_otp_patient_id)
        |> delete_session(:pending_otpclinic_id)
        |> put_session(:patient_id, patient_id)
        |> put_session(:clinic_id, clinic_id)
        |> put_flash(
          :info,
          "Successfully authenticated. Welcome #{patient.first_name || "Patient"}!"
        )
        |> redirect(to: ~p"/patient/dashboard")

      {:error, :invalid_otp} ->
        conn
        |> put_flash(:error, "Invalid OTP. Please try again.")
        |> redirect(to: ~p"/patient/verify-otp?clinic_id=#{clinic_id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/patient/request-otp?clinic_id=#{clinic_id}")
    end
  end

  @doc """
  Verifies the submitted OTP and authenticates the patient if valid (without clinic_id in params).
  """
  def verify_otp(conn, %{"otp" => otp}) do
    patient_id = get_session(conn, :pending_otp_patient_id)
    # Get the clinic_id from the session or use default
    clinic_id =
      get_session(conn, :pending_otpclinic_id) ||
        Application.get_env(:clinicpro, :default_clinic_id, "1")

    case OTP.validate_otp(patient_id, clinic_id, otp) do
      {:ok, _otp_secret} ->
        # Fetch the patient to get their details
        patient = Repo.get(Patient, patient_id)

        conn
        |> delete_session(:pending_otp_patient_id)
        |> delete_session(:pending_otpclinic_id)
        |> put_session(:patient_id, patient_id)
        |> put_session(:clinic_id, clinic_id)
        |> put_flash(
          :info,
          "Successfully authenticated. Welcome #{patient.first_name || "Patient"}!"
        )
        |> redirect(to: ~p"/patient/dashboard")

      {:error, :invalid_otp} ->
        conn
        |> put_flash(:error, "Invalid OTP. Please try again.")
        |> redirect(to: ~p"/patient/verify-otp")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/patient/request-otp")
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
        clinic_id = get_session(conn, :clinic_id)
        patient = Repo.get(Patient, patient_id)

        # Here you would fetch real data for the dashboard
        # For now, we'll just render the template with the patient
        conn
        |> put_layout(html: :root)
        |> render("dashboard.html", patient: patient, clinic_id: clinic_id)
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

  defp find_or_create_patient(params, clinic_id) do
    # Try to find by phone number first, then by email
    patient =
      cond do
        params["phone_number"] && params["phone_number"] != "" ->
          Repo.get_by(Patient, phone_number: params["phone_number"], clinic_id: clinic_id)

        params["email"] && params["email"] != "" ->
          Repo.get_by(Patient, email: params["email"], clinic_id: clinic_id)

        true ->
          nil
      end

    # If patient not found, create a new one
    if patient do
      patient
    else
      # Add clinic_id to params
      params_with_clinic = Map.put(params, "clinic_id", clinic_id)

      {:ok, new_patient} =
        %Patient{}
        |> Patient.changeset(params_with_clinic)
        |> Repo.insert()

      new_patient
    end
  end

  @doc """
  Display the appointment booking form.
  """
  def book_appointment(conn, _params) do
    # Get patient from session
    patient_id = get_session(conn, :patient_id)
    clinic_id = get_session(conn, :clinic_id)

    # For now, render a simple booking form
    conn
    |> put_layout(html: :root)
    |> render("book_appointment.html", patient_id: patient_id, clinic_id: clinic_id)
  end

  @doc """
  Process appointment booking.
  """
  def create_appointment(conn, %{"appointment" => appointment_params}) do
    patient_id = get_session(conn, :patient_id)
    clinic_id = get_session(conn, :clinic_id)

    # Add patient and clinic info to params
    full_params =
      appointment_params
      |> Map.put("patient_id", patient_id)
      |> Map.put("clinic_id", clinic_id)

    # For now, just redirect back with success message
    conn
    |> put_flash(:info, "Appointment booking request submitted successfully!")
    |> redirect(to: ~p"/patient/dashboard")
  end
end
