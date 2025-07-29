defmodule ClinicproWeb.AdminController do
  use ClinicproWeb, :controller
  require Logger

  # Apply authentication plug to ensure only authenticated admins can access
  plug :ensure_authenticated_admin when action not in [:login, :login_submit]

  @doc """
  Display the admin dashboard.
  """
  def dashboard(conn, _params) do
    # Get summary statistics
    stats = %{
      total_doctors: 15,
      total_patients: 120,
      total_appointments: 45,
      upcoming_appointments: 20,
      completed_appointments: 25
    }

    # Get recent activity
    recent_activity = get_recent_activity()

    render(conn, :dashboard,
      stats: stats,
      recent_activity: recent_activity
    )
  end

  @doc """
  Display the admin login page.
  """
  def login(conn, _params) do
    conn
    |> put_layout(html: :root)
    |> render("login.html")
  end

  @doc """
  Process admin login.
  """
  def login_submit(conn, %{"email" => email, "password" => password}) do
    case Clinicpro.Admin.authenticate(email, password) do
      {:ok, admin} ->
        conn
        |> put_session(:admin_id, admin.id)
        |> put_session(:admin_name, admin.name)
        |> put_session(:admin_role, admin.role)
        |> put_flash(:info, "Logged in successfully")
        |> redirect(to: ~p"/admin/dashboard")

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render(:login)
    end
  end

  @doc """
  Process admin logout.
  """
  def logout(conn, _params) do
    conn
    |> delete_session(:admin_id)
    |> delete_session(:admin_name)
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/admin/login")
  end

  # Doctors management is implemented below with real database integration

  @doc """
  Display the form to add a new doctor.
  """
  def new_doctor(conn, _params) do
    changeset = Clinicpro.Doctor.change(%Clinicpro.Doctor{})
    render(conn, :new_doctor, changeset: changeset)
  end

  @doc """
  Process the form to add a new doctor.
  """
  def create_doctor(conn, %{"doctor" => doctor_params}) do
    case Clinicpro.Doctor.create(doctor_params) do
      {:ok, _doctor} ->
        conn
        |> put_flash(:info, "Doctor created successfully")
        |> redirect(to: ~p"/admin/doctors")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error creating doctor: #{error_messages(changeset)}")
        |> render(:new_doctor, changeset: changeset)
    end
  end

  @doc """
  Display the form to edit a doctor.
  """
  def edit_doctor(conn, %{"id" => doctor_id}) do
    case get_doctor(doctor_id) do
      {:ok, doctor} ->
        changeset = Clinicpro.Doctor.change(doctor)
        render(conn, :edit_doctor, doctor: doctor, changeset: changeset)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Cannot edit doctor: #{reason}")
        |> redirect(to: ~p"/admin/doctors")
    end
  end

  @doc """
  Process the form to update a doctor.
  """
  def update_doctor(conn, %{"id" => doctor_id, "doctor" => doctor_params}) do
    case Clinicpro.Doctor.update(doctor_id, doctor_params) do
      {:ok, _doctor} ->
        conn
        |> put_flash(:info, "Doctor updated successfully")
        |> redirect(to: ~p"/admin/doctors")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error updating doctor: #{error_messages(changeset)}")
        |> redirect(to: ~p"/admin/edit_doctor/#{doctor_id}")
    end
  end

  @doc """
  Process the request to delete a doctor.
  """
  def delete_doctor(conn, %{"id" => doctor_id}) do
    case Clinicpro.Doctor.get(doctor_id) do
      nil ->
        conn
        |> put_flash(:error, "Doctor not found")
        |> redirect(to: ~p"/admin/doctors")

      doctor ->
        # Instead of hard deleting, we set active to false
        case Clinicpro.Doctor.update(doctor, %{active: false}) do
          {:ok, _updated} ->
            conn
            |> put_flash(:info, "Doctor deactivated successfully")
            |> redirect(to: ~p"/admin/doctors")

          {:error, changeset} ->
            conn
            |> put_flash(:error, "Error deactivating doctor: #{error_messages(changeset)}")
            |> redirect(to: ~p"/admin/doctors")
        end
    end
  end

  @doc """
  Display the patients management page.
  """
  def patients(conn, _params) do
    patients = Clinicpro.Patient.list()
    render(conn, :patients, patients: patients)
  end

  @doc """
  Display the form to add a new patient.
  """
  def new_patient(conn, _params) do
    changeset = Clinicpro.Patient.changeset(%Clinicpro.Patient{}, %{})
    render(conn, :new_patient, changeset: changeset)
  end

  @doc """
  Process the form to add a new patient.
  """
  def create_patient(conn, %{"patient" => patient_params}) do
    case Clinicpro.Patient.create(patient_params) do
      {:ok, _patient} ->
        conn
        |> put_flash(:info, "Patient created successfully")
        |> redirect(to: ~p"/admin/patients")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error creating patient: #{error_messages(changeset)}")
        |> render(:new_patient, changeset: changeset)
    end
  end

  @doc """
  Display the form to edit a patient.
  """
  def edit_patient(conn, %{"id" => patient_id}) do
    case get_patient(patient_id) do
      {:ok, patient} ->
        changeset = Clinicpro.Patient.changeset(patient, %{})
        render(conn, :edit_patient, patient: patient, changeset: changeset)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Cannot edit patient: #{reason}")
        |> redirect(to: ~p"/admin/patients")
    end
  end

  @doc """
  Process the form to update a patient.
  """
  def update_patient(conn, %{"id" => patient_id, "patient" => patient_params}) do
    case Clinicpro.Patient.update(patient_id, patient_params) do
      {:ok, _patient} ->
        conn
        |> put_flash(:info, "Patient updated successfully")
        |> redirect(to: ~p"/admin/patients")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Error updating patient: #{error_messages(changeset)}")
        |> redirect(to: ~p"/admin/edit_patient/#{patient_id}")
    end
  end

  @doc """
  Process the request to delete a patient.
  """
  def delete_patient(conn, %{"id" => patient_id}) do
    case Clinicpro.Patient.get(patient_id) do
      nil ->
        conn
        |> put_flash(:error, "Patient not found")
        |> redirect(to: ~p"/admin/patients")

      patient ->
        # Instead of hard deleting, we set active to false
        case Clinicpro.Patient.update(patient, %{active: false}) do
          {:ok, _updated} ->
            conn
            |> put_flash(:info, "Patient deactivated successfully")
            |> redirect(to: ~p"/admin/patients")

          {:error, changeset} ->
            conn
            |> put_flash(:error, "Error deactivating patient: #{error_messages(changeset)}")
            |> redirect(to: ~p"/admin/patients")
        end
    end
  end

  @doc """
  Display the appointments management page.
  """
  def appointments(conn, _params) do
    appointments = Clinicpro.Appointment.list()
    render(conn, :appointments, appointments: appointments)
  end

  @doc """
  Display the form to add a new appointment.
  """
  def newappointment(conn, _params) do
    doctors = Clinicpro.Doctor.listactive()
    patients = Clinicpro.Patient.listactive()

    render(conn, :newappointment,
      doctors: doctors,
      patients: patients
    )
  end

  @doc """
  Process the form to add a new appointment.
  """
  def createappointment(conn, %{"appointment" => appointment_params}) do
    case Clinicpro.Appointment.create(appointment_params) do
      {:ok, _appointment} ->
        conn
        |> put_flash(:info, "Appointment created successfully")
        |> redirect(to: ~p"/admin/appointments")

      {:error, changeset} ->
        doctors = Clinicpro.Doctor.listactive()
        patients = Clinicpro.Patient.listactive()

        conn
        |> put_flash(:error, "Error creating appointment: #{error_messages(changeset)}")
        |> render(:newappointment,
          doctors: doctors,
          patients: patients,
          changeset: changeset
        )
    end
  end

  @doc """
  Display the form to edit an appointment.
  """
  def editappointment(conn, %{"id" => appointment_id}) do
    case getappointment(appointment_id) do
      {:ok, appointment} ->
        doctors = Clinicpro.Doctor.listactive()
        patients = Clinicpro.Patient.listactive()
        changeset = Clinicpro.Appointment.change(appointment)

        render(conn, :editappointment,
          appointment: appointment,
          doctors: doctors,
          patients: patients,
          changeset: changeset
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, "Cannot edit appointment: #{reason}")
        |> redirect(to: ~p"/admin/appointments")
    end
  end

  @doc """
  Process the form to update an appointment.
  """
  def updateappointment(conn, %{"id" => appointment_id, "appointment" => appointment_params}) do
    case Clinicpro.Appointment.update(appointment_id, appointment_params) do
      {:ok, _appointment} ->
        conn
        |> put_flash(:info, "Appointment updated successfully")
        |> redirect(to: ~p"/admin/appointments")

      {:error, changeset} ->
        doctors = Clinicpro.Doctor.listactive()
        patients = Clinicpro.Patient.listactive()

        conn
        |> put_flash(:error, "Error updating appointment: #{error_messages(changeset)}")
        |> redirect(to: ~p"/admin/editappointment/#{appointment_id}")
    end
  end

  @doc """
  Process the request to delete an appointment.
  """
  def deleteappointment(conn, %{"id" => appointment_id}) do
    case Clinicpro.Appointment.get(appointment_id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found")
        |> redirect(to: ~p"/admin/appointments")

      appointment ->
        # Update the appointment status to cancelled instead of hard deleting
        case Clinicpro.Appointment.update(appointment, %{status: "cancelled"}) do
          {:ok, _updated} ->
            conn
            |> put_flash(:info, "Appointment cancelled successfully")
            |> redirect(to: ~p"/admin/appointments")

          {:error, changeset} ->
            conn
            |> put_flash(:error, "Error cancelling appointment: #{error_messages(changeset)}")
            |> redirect(to: ~p"/admin/appointments")
        end
    end
  end

  @doc """
  Display the clinic settings page.
  """
  def settings(conn, _params) do
    settings = get_clinic_settings()
    admins = Clinicpro.Admin.list()
    render(conn, :settings, settings: settings, admins: admins)
  end

  @doc """
  Process the form to update clinic settings.
  """
  def update_settings(conn, %{"settings" => settings_params}) do
    # Update each setting in the database
    results =
      Enum.map(settings_params, fn {key, value} ->
        Clinicpro.ClinicSetting.set(key, value)
      end)

    # Check if any updates failed
    if Enum.all?(results, fn result -> match?({:ok, _unused}, result) end) do
      conn
      |> put_flash(:info, "Clinic settings updated successfully")
      |> redirect(to: ~p"/admin/settings")
    else
      # Extract error messages from failed updates
      errors =
        results
        |> Enum.filter(fn result -> match?({:error, _unused}, result) end)
        |> Enum.map(fn {:error, changeset} -> error_messages(changeset) end)
        |> Enum.join("; ")

      conn
      |> put_flash(:error, "Failed to update some settings: #{errors}")
      |> redirect(to: ~p"/admin/settings")
    end
  end

  # Private helpers

  defp ensure_authenticated_admin(conn, _opts) do
    admin_id = get_session(conn, :admin_id)

    if admin_id do
      # Check if the admin still exists and is active
      case Clinicpro.Admin.get(admin_id) do
        %{active: true} = admin ->
          # Assign the admin to the connection for use in templates
          assign(conn, :current_admin, admin)

        _unused ->
          # Admin doesn't exist or is inactive, log them out
          conn
          |> delete_session(:admin_id)
          |> delete_session(:admin_name)
          |> delete_session(:admin_role)
          |> put_flash(:error, "Your session has expired or your account has been deactivated")
          |> redirect(to: ~p"/admin/login")
          |> halt()
      end
    else
      conn
      |> put_flash(:error, "You must be logged in as an admin to access this page")
      |> redirect(to: ~p"/admin/login")
      |> halt()
    end
  end

  defp get_recent_activity do
    # Get recent appointments
    recent_appointments =
      Clinicpro.Appointment.list(limit: 5)
      |> Enum.map(fn appointment ->
        # Preload doctor and patient if not already loaded
        appointment =
          if Ecto.assoc_loaded?(appointment.doctor) && Ecto.assoc_loaded?(appointment.patient) do
            appointment
          else
            Clinicpro.Repo.preload(appointment, [:doctor, :patient])
          end

        doctor_name = if appointment.doctor, do: appointment.doctor.name, else: "Unknown Doctor"

        patient_name =
          if appointment.patient,
            do: Clinicpro.Patient.full_name(appointment.patient),
            else: "Unknown Patient"

        %{
          type: "appointment",
          action: "scheduled",
          user: doctor_name,
          timestamp: appointment.inserted_at || ~U[2023-01-01 00:00:00Z],
          details: "#{appointment.type} appointment with #{patient_name} on #{appointment.date}"
        }
      end)

    # Get recent _patients
    recent_patients =
      Clinicpro.Patient.list(limit: 3)
      |> Enum.map(fn patient ->
        %{
          type: "patient",
          action: "registered",
          user: "System",
          timestamp: patient.inserted_at || ~U[2023-01-01 00:00:00Z],
          details: "New patient registration: #{Clinicpro.Patient.full_name(patient)}"
        }
      end)

    # Get recent _doctors
    recent_doctors =
      Clinicpro.Doctor.list(limit: 2)
      |> Enum.map(fn doctor ->
        %{
          type: "doctor",
          action: "registered",
          user: "Admin",
          timestamp: doctor.inserted_at || ~U[2023-01-01 00:00:00Z],
          details: "New doctor added: #{doctor.name}, #{doctor.specialty}"
        }
      end)

    # Combine and sort by timestamp (most recent first)
    (recent_appointments ++ recent_patients ++ recent_doctors)
    |> Enum.sort_by(fn %{timestamp: timestamp} -> DateTime.to_unix(timestamp) end, :desc)
    |> Enum.take(5)
  end

  # Unused function
  # defp get_doctors do
  #   # Get doctors from the database
  #   Clinicpro.Doctor.list()
  # end

  defp get_doctor(doctor_id) do
    # Get doctor from the database with appointments preloaded
    case Clinicpro.Doctor.get_with_appointments(doctor_id) do
      nil -> {:error, "Doctor not found"}
      doctor -> {:ok, doctor}
    end
  end

  # Unused function
  # defp get_patients do
  #   # Get patients from the database
  #   Clinicpro.Patient.list()
  # end

  defp get_patient(patient_id) do
    # Get patient from the database with appointments preloaded
    case Clinicpro.Patient.get_with_appointments(patient_id) do
      nil -> {:error, "Patient not found"}
      patient -> {:ok, patient}
    end
  end

  # Unused function
  # defp get_appointments do
  #   # Get appointments from the database with doctors and patients preloaded
  #   Clinicpro.Appointment.list_with_associations()
  # end

  defp getappointment(appointment_id) do
    # Get appointment from the database with doctor and patient preloaded
    case Clinicpro.Appointment.get_with_associations(appointment_id) do
      nil -> {:error, "Appointment not found"}
      appointment -> {:ok, appointment}
    end
  end

  defp get_clinic_settings do
    # Get settings from the database
    settings = Clinicpro.ClinicSetting.get_all()

    # Convert string values to appropriate types
    %{
      clinic_name: settings["clinic_name"],
      address: settings["clinic_address"],
      phone: settings["clinic_phone"],
      email: settings["clinic_email"],
      website: settings["clinic_website"],
      tax_id: settings["tax_id"] || "",
      appointment_reminders: settings["appointment_reminders"] == "true",
      appointment_confirmations: settings["appointment_confirmations"] == "true" || true,
      doctor_notifications: settings["doctor_notifications"] == "true" || true,
      admin_notifications: settings["admin_notifications"] == "true" || true,
      reminder_time: String.to_integer(settings["appointment_reminders"] || "24"),
      monday_from: settings["business_hours_mon"] |> String.split("-") |> List.first(),
      monday_to: settings["business_hours_mon"] |> String.split("-") |> List.last(),
      monday_closed: settings["business_hours_mon"] == "Closed",
      tuesday_from: settings["business_hours_tue"] |> String.split("-") |> List.first(),
      tuesday_to: settings["business_hours_tue"] |> String.split("-") |> List.last(),
      tuesday_closed: settings["business_hours_tue"] == "Closed",
      wednesday_from: settings["business_hours_wed"] |> String.split("-") |> List.first(),
      wednesday_to: settings["business_hours_wed"] |> String.split("-") |> List.last(),
      wednesday_closed: settings["business_hours_wed"] == "Closed",
      thursday_from: settings["business_hours_thu"] |> String.split("-") |> List.first(),
      thursday_to: settings["business_hours_thu"] |> String.split("-") |> List.last(),
      thursday_closed: settings["business_hours_thu"] == "Closed",
      friday_from: settings["business_hours_fri"] |> String.split("-") |> List.first(),
      friday_to: settings["business_hours_fri"] |> String.split("-") |> List.last(),
      friday_closed: settings["business_hours_fri"] == "Closed",
      saturday_from: settings["business_hours_sat"] |> String.split("-") |> List.first(),
      saturday_to: settings["business_hours_sat"] |> String.split("-") |> List.last(),
      saturday_closed: settings["business_hours_sat"] == "Closed",
      sunday_from: settings["business_hours_sun"] |> String.split("-") |> List.first("Closed"),
      sunday_to: settings["business_hours_sun"] |> String.split("-") |> List.last("Closed"),
      sunday_closed: settings["business_hours_sun"] == "Closed"
    }
  end

  @doc """
  Display the doctors management page.
  """
  def doctors(conn, _params) do
    doctors = Clinicpro.Doctor.list()
    render(conn, :doctors, doctors: doctors)
  end

  # Unused function
  # defp get_admins do
  #   # Get admins from the database
  #   Clinicpro.Admin.list()
  # end

  # Helper to format changeset errors into a readable string
  defp error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _unused, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k} #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end
end
