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
    render(conn, :login)
  end

  @doc """
  Process admin login.
  """
  def login_submit(conn, %{"email" => email, "password" => password}) do
    # This is a placeholder implementation
    # In a real app, this would authenticate against the database
    
    if email == "admin@clinicpro.com" && password == "admin123" do
      conn
      |> put_session(:admin_id, "admin-1")
      |> put_session(:admin_name, "Admin User")
      |> put_flash(:info, "Logged in successfully")
      |> redirect(to: ~p"/admin/dashboard")
    else
      conn
      |> put_flash(:error, "Invalid email or password")
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

  @doc """
  Display the doctors management page.
  """
  def doctors(conn, _params) do
    doctors = get_doctors()
    render(conn, :doctors, doctors: doctors)
  end

  @doc """
  Display the form to add a new doctor.
  """
  def new_doctor(conn, _params) do
    render(conn, :new_doctor)
  end

  @doc """
  Process the form to add a new doctor.
  """
  def create_doctor(conn, %{"doctor" => doctor_params}) do
    # This is a placeholder implementation
    # In a real app, this would create a doctor in the database
    
    Logger.info("Creating doctor: #{inspect(doctor_params)}")
    
    conn
    |> put_flash(:info, "Doctor created successfully")
    |> redirect(to: ~p"/admin/doctors")
  end

  @doc """
  Display the form to edit a doctor.
  """
  def edit_doctor(conn, %{"id" => doctor_id}) do
    case get_doctor(doctor_id) do
      {:ok, doctor} ->
        render(conn, :edit_doctor, doctor: doctor)
        
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
    # This is a placeholder implementation
    # In a real app, this would update a doctor in the database
    
    Logger.info("Updating doctor #{doctor_id}: #{inspect(doctor_params)}")
    
    conn
    |> put_flash(:info, "Doctor updated successfully")
    |> redirect(to: ~p"/admin/doctors")
  end

  @doc """
  Process the request to delete a doctor.
  """
  def delete_doctor(conn, %{"id" => doctor_id}) do
    # This is a placeholder implementation
    # In a real app, this would delete a doctor from the database
    
    Logger.info("Deleting doctor #{doctor_id}")
    
    conn
    |> put_flash(:info, "Doctor deleted successfully")
    |> redirect(to: ~p"/admin/doctors")
  end

  @doc """
  Display the patients management page.
  """
  def patients(conn, _params) do
    patients = get_patients()
    render(conn, :patients, patients: patients)
  end

  @doc """
  Display the form to add a new patient.
  """
  def new_patient(conn, _params) do
    render(conn, :new_patient)
  end

  @doc """
  Process the form to add a new patient.
  """
  def create_patient(conn, %{"patient" => patient_params}) do
    # This is a placeholder implementation
    # In a real app, this would create a patient in the database
    
    Logger.info("Creating patient: #{inspect(patient_params)}")
    
    conn
    |> put_flash(:info, "Patient created successfully")
    |> redirect(to: ~p"/admin/patients")
  end

  @doc """
  Display the form to edit a patient.
  """
  def edit_patient(conn, %{"id" => patient_id}) do
    case get_patient(patient_id) do
      {:ok, patient} ->
        render(conn, :edit_patient, patient: patient)
        
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
    # This is a placeholder implementation
    # In a real app, this would update a patient in the database
    
    Logger.info("Updating patient #{patient_id}: #{inspect(patient_params)}")
    
    conn
    |> put_flash(:info, "Patient updated successfully")
    |> redirect(to: ~p"/admin/patients")
  end

  @doc """
  Process the request to delete a patient.
  """
  def delete_patient(conn, %{"id" => patient_id}) do
    # This is a placeholder implementation
    # In a real app, this would delete a patient from the database
    
    Logger.info("Deleting patient #{patient_id}")
    
    conn
    |> put_flash(:info, "Patient deleted successfully")
    |> redirect(to: ~p"/admin/patients")
  end

  @doc """
  Display the appointments management page.
  """
  def appointments(conn, _params) do
    appointments = get_appointments()
    render(conn, :appointments, appointments: appointments)
  end

  @doc """
  Display the form to add a new appointment.
  """
  def new_appointment(conn, _params) do
    doctors = get_doctors()
    patients = get_patients()
    
    render(conn, :new_appointment,
      doctors: doctors,
      patients: patients
    )
  end

  @doc """
  Process the form to add a new appointment.
  """
  def create_appointment(conn, %{"appointment" => appointment_params}) do
    # This is a placeholder implementation
    # In a real app, this would create an appointment in the database
    
    Logger.info("Creating appointment: #{inspect(appointment_params)}")
    
    conn
    |> put_flash(:info, "Appointment created successfully")
    |> redirect(to: ~p"/admin/appointments")
  end

  @doc """
  Display the form to edit an appointment.
  """
  def edit_appointment(conn, %{"id" => appointment_id}) do
    case get_appointment(appointment_id) do
      {:ok, appointment} ->
        doctors = get_doctors()
        patients = get_patients()
        
        render(conn, :edit_appointment,
          appointment: appointment,
          doctors: doctors,
          patients: patients
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
  def update_appointment(conn, %{"id" => appointment_id, "appointment" => appointment_params}) do
    # This is a placeholder implementation
    # In a real app, this would update an appointment in the database
    
    Logger.info("Updating appointment #{appointment_id}: #{inspect(appointment_params)}")
    
    conn
    |> put_flash(:info, "Appointment updated successfully")
    |> redirect(to: ~p"/admin/appointments")
  end

  @doc """
  Process the request to delete an appointment.
  """
  def delete_appointment(conn, %{"id" => appointment_id}) do
    # This is a placeholder implementation
    # In a real app, this would delete an appointment from the database
    
    Logger.info("Deleting appointment #{appointment_id}")
    
    conn
    |> put_flash(:info, "Appointment deleted successfully")
    |> redirect(to: ~p"/admin/appointments")
  end

  @doc """
  Display the clinic settings page.
  """
  def settings(conn, _params) do
    settings = get_clinic_settings()
    render(conn, :settings, settings: settings)
  end

  @doc """
  Process the form to update clinic settings.
  """
  def update_settings(conn, %{"settings" => settings_params}) do
    # This is a placeholder implementation
    # In a real app, this would update clinic settings in the database
    
    Logger.info("Updating clinic settings: #{inspect(settings_params)}")
    
    conn
    |> put_flash(:info, "Clinic settings updated successfully")
    |> redirect(to: ~p"/admin/settings")
  end

  # Private helpers

  defp ensure_authenticated_admin(conn, _opts) do
    if get_session(conn, :admin_id) do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in as an admin to access this page")
      |> redirect(to: ~p"/admin/login")
      |> halt()
    end
  end

  defp get_recent_activity do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    [
      %{
        type: "appointment",
        action: "created",
        user: "Dr. Smith",
        timestamp: ~U[2023-06-15 10:30:00Z],
        details: "New appointment with Patient #123"
      },
      %{
        type: "patient",
        action: "registered",
        user: "System",
        timestamp: ~U[2023-06-15 09:45:00Z],
        details: "New patient registration: John Doe"
      },
      %{
        type: "doctor",
        action: "updated",
        user: "Admin",
        timestamp: ~U[2023-06-14 16:20:00Z],
        details: "Updated doctor profile: Dr. Johnson"
      },
      %{
        type: "appointment",
        action: "completed",
        user: "Dr. Williams",
        timestamp: ~U[2023-06-14 15:00:00Z],
        details: "Completed appointment with Patient #456"
      },
      %{
        type: "settings",
        action: "updated",
        user: "Admin",
        timestamp: ~U[2023-06-14 11:10:00Z],
        details: "Updated clinic operating hours"
      }
    ]
  end

  defp get_doctors do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    Enum.map(1..10, fn i ->
      %{
        id: "doctor-#{i}",
        name: "Dr. #{["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia", "Rodriguez", "Wilson"] |> Enum.at(rem(i - 1, 10))}",
        specialty: ["Cardiology", "Dermatology", "Family Medicine", "Neurology", "Pediatrics", "Orthopedics", "Psychiatry", "Oncology", "Gynecology", "Urology"] |> Enum.at(rem(i - 1, 10)),
        email: "doctor#{i}@clinicpro.com",
        phone: "+1 (555) #{100 + i}-#{1000 + i}",
        status: ["Active", "Active", "Active", "On Leave", "Active"] |> Enum.at(rem(i - 1, 5))
      }
    end)
  end

  defp get_doctor(doctor_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    doctor = %{
      id: doctor_id,
      name: "Dr. Smith",
      specialty: "Cardiology",
      email: "drsmith@clinicpro.com",
      phone: "+1 (555) 123-4567",
      status: "Active",
      address: "123 Medical Center Dr",
      city: "New York",
      state: "NY",
      zip: "10001",
      bio: "Dr. Smith is a board-certified cardiologist with over 15 years of experience.",
      education: "Harvard Medical School",
      languages: ["English", "Spanish"]
    }
    
    {:ok, doctor}
  end

  defp get_patients do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    Enum.map(1..10, fn i ->
      %{
        id: "patient-#{i}",
        name: "#{["John", "Jane", "Robert", "Mary", "Michael", "Linda", "William", "Patricia", "David", "Jennifer"] |> Enum.at(rem(i - 1, 10))} #{["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia", "Rodriguez", "Wilson"] |> Enum.at(rem(i - 1, 10))}",
        email: "patient#{i}@example.com",
        phone: "+1 (555) #{200 + i}-#{2000 + i}",
        date_of_birth: Date.add(~D[1970-01-01], i * 500),
        gender: ["Male", "Female"] |> Enum.at(rem(i - 1, 2)),
        status: ["Active", "Active", "Inactive", "Active", "Active"] |> Enum.at(rem(i - 1, 5))
      }
    end)
  end

  defp get_patient(patient_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    patient = %{
      id: patient_id,
      name: "John Smith",
      email: "john.smith@example.com",
      phone: "+1 (555) 123-4567",
      date_of_birth: ~D[1980-05-15],
      gender: "Male",
      status: "Active",
      address: "456 Residential St",
      city: "New York",
      state: "NY",
      zip: "10001",
      emergency_contact_name: "Jane Smith",
      emergency_contact_phone: "+1 (555) 987-6543",
      insurance_provider: "Health Insurance Co",
      insurance_policy_number: "POL123456789"
    }
    
    {:ok, patient}
  end

  defp get_appointments do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    Enum.map(1..10, fn i ->
      %{
        id: "appt-#{i}",
        patient_name: "#{["John", "Jane", "Robert", "Mary", "Michael", "Linda", "William", "Patricia", "David", "Jennifer"] |> Enum.at(rem(i - 1, 10))} #{["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia", "Rodriguez", "Wilson"] |> Enum.at(rem(i - 1, 10))}",
        doctor_name: "Dr. #{["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia", "Rodriguez", "Wilson"] |> Enum.at(rem(i - 1, 10))}",
        date: Date.add(Date.utc_today(), rem(i, 14) - 7),
        time: "#{9 + rem(i - 1, 8)}:#{["00", "30"] |> Enum.at(rem(i - 1, 2))}",
        status: ["Scheduled", "Completed", "Cancelled", "No-show", "Rescheduled"] |> Enum.at(rem(i - 1, 5)),
        reason: ["Regular checkup", "Follow-up", "Consultation", "Prescription renewal", "Test results"] |> Enum.at(rem(i - 1, 5))
      }
    end)
  end

  defp get_appointment(appointment_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    appointment = %{
      id: appointment_id,
      patient_id: "patient-1",
      patient_name: "John Smith",
      doctor_id: "doctor-1",
      doctor_name: "Dr. Smith",
      date: Date.add(Date.utc_today(), 2),
      time: "10:00",
      duration: 30,
      status: "Scheduled",
      reason: "Regular checkup",
      notes: "Patient has requested a discussion about recent test results."
    }
    
    {:ok, appointment}
  end

  defp get_clinic_settings do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    %{
      clinic_name: "ClinicPro Medical Center",
      address: "789 Healthcare Blvd",
      city: "New York",
      state: "NY",
      zip: "10001",
      phone: "+1 (555) 987-6543",
      email: "info@clinicpro.com",
      website: "https://clinicpro.com",
      operating_hours: %{
        monday: %{start: "09:00", end: "17:00"},
        tuesday: %{start: "09:00", end: "17:00"},
        wednesday: %{start: "09:00", end: "17:00"},
        thursday: %{start: "09:00", end: "17:00"},
        friday: %{start: "09:00", end: "17:00"},
        saturday: %{start: "10:00", end: "14:00"},
        sunday: %{start: nil, end: nil}
      },
      appointment_duration: 30,
      notification_settings: %{
        email_reminders: true,
        sms_reminders: true,
        reminder_hours_before: 24
      },
      payment_methods: ["Cash", "Credit Card", "Insurance", "M-Pesa"]
    }
  end
end
