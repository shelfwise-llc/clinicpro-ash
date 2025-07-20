defmodule ClinicproWeb.AdminBypassController do
  use ClinicproWeb, :controller
  alias Clinicpro.Repo
  alias Clinicpro.AdminBypass.{Doctor, Patient, Appointment, Seeder}
  import Ecto.Query

  # Define Admin schema for direct Ecto operations (keeping this one as is)
  defmodule Admin do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "admins" do
      field :name, :string
      field :email, :string
      field :role, :string
      field :password_hash, :string
      field :active, :boolean, default: true
      field :password, :string, virtual: true

      timestamps(type: :utc_datetime)
    end

    def changeset(admin, attrs) do
      admin
      |> cast(attrs, [:name, :email, :password, :role, :active])
      |> validate_required([:name, :email, :password, :role])
      |> unique_constraint(:email)
      |> put_password_hash()
    end

    defp put_password_hash(changeset) do
      case changeset do
        %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
          put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
        _ ->
          changeset
      end
    end
  end

  # Admin Panel Routes
  def index(conn, _params) do
    recent_activity = get_recent_activity()
    render(conn, :index, page_title: "Admin Dashboard", recent_activity: recent_activity)
  end

  # Doctor CRUD operations
  def doctors(conn, _params) do
    doctors = Doctor.list_doctors()
    render(conn, :doctors, page_title: "Doctors", doctors: doctors)
  end

  def new_doctor(conn, _params) do
    changeset = Doctor.change_doctor(%Doctor{})
    render(conn, :new_doctor, page_title: "New Doctor", changeset: changeset)
  end

  def create_doctor(conn, %{"doctor" => doctor_params}) do
    case Doctor.create_doctor(doctor_params) do
      {:ok, _doctor} ->
        conn
        |> put_flash(:info, "Doctor created successfully.")
        |> redirect(to: ~p"/admin_bypass/doctors")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new_doctor, page_title: "New Doctor", changeset: changeset)
    end
  end

  def edit_doctor(conn, %{"id" => doctor_id}) do
    doctor = Doctor.get_doctor!(doctor_id)
    changeset = Doctor.change_doctor(doctor)
    render(conn, :edit_doctor, page_title: "Edit Doctor", doctor: doctor, changeset: changeset)
  end

  def update_doctor(conn, %{"id" => doctor_id, "doctor" => doctor_params}) do
    doctor = Doctor.get_doctor!(doctor_id)

    case Doctor.update_doctor(doctor, doctor_params) do
      {:ok, _doctor} ->
        conn
        |> put_flash(:info, "Doctor updated successfully.")
        |> redirect(to: ~p"/admin_bypass/doctors")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit_doctor, page_title: "Edit Doctor", doctor: doctor, changeset: changeset)
    end
  end

  def delete_doctor(conn, %{"id" => doctor_id}) do
    doctor = Doctor.get_doctor!(doctor_id)
    {:ok, _} = Doctor.delete_doctor(doctor)

    conn
    |> put_flash(:info, "Doctor deleted successfully.")
    |> redirect(to: ~p"/admin_bypass/doctors")
  end

  # Patient CRUD operations
  def patients(conn, _params) do
    patients = Patient.list_patients()
    render(conn, :patients, page_title: "Patients", patients: patients)
  end

  def new_patient(conn, _params) do
    changeset = Patient.change_patient(%Patient{})
    render(conn, :new_patient, page_title: "New Patient", changeset: changeset)
  end

  def create_patient(conn, %{"patient" => patient_params}) do
    case Patient.create_patient(patient_params) do
      {:ok, _patient} ->
        conn
        |> put_flash(:info, "Patient created successfully.")
        |> redirect(to: ~p"/admin_bypass/patients")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new_patient, page_title: "New Patient", changeset: changeset)
    end
  end

  def edit_patient(conn, %{"id" => patient_id}) do
    patient = Patient.get_patient!(patient_id)
    changeset = Patient.change_patient(patient)
    render(conn, :edit_patient, page_title: "Edit Patient", patient: patient, changeset: changeset)
  end

  def update_patient(conn, %{"id" => patient_id, "patient" => patient_params}) do
    patient = Patient.get_patient!(patient_id)

    case Patient.update_patient(patient, patient_params) do
      {:ok, _patient} ->
        conn
        |> put_flash(:info, "Patient updated successfully.")
        |> redirect(to: ~p"/admin_bypass/patients")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit_patient, page_title: "Edit Patient", patient: patient, changeset: changeset)
    end
  end

  def delete_patient(conn, %{"id" => patient_id}) do
    patient = Patient.get_patient!(patient_id)
    {:ok, _} = Patient.delete_patient(patient)

    conn
    |> put_flash(:info, "Patient deleted successfully.")
    |> redirect(to: ~p"/admin_bypass/patients")
  end

  # Appointment CRUD operations
  def appointments(conn, _params) do
    appointments = Appointment.list_appointments_with_associations()
    render(conn, :appointments, page_title: "Appointments", appointments: appointments)
  end

  def new_appointment(conn, _params) do
    doctors = Doctor.list_doctors()
    patients = Patient.list_patients()
    changeset = Appointment.change_appointment(%Appointment{})
    
    render(conn, :new_appointment, 
      page_title: "New Appointment", 
      changeset: changeset, 
      doctors: doctors,
      patients: patients
    )
  end

  def create_appointment(conn, %{"appointment" => appointment_params}) do
    case Appointment.create_appointment(appointment_params) do
      {:ok, _appointment} ->
        conn
        |> put_flash(:info, "Appointment created successfully.")
        |> redirect(to: ~p"/admin_bypass/appointments")

      {:error, %Ecto.Changeset{} = changeset} ->
        doctors = Doctor.list_doctors()
        patients = Patient.list_patients()
        render(conn, :new_appointment, 
          page_title: "New Appointment", 
          changeset: changeset,
          doctors: doctors,
          patients: patients
        )
    end
  end

  def edit_appointment(conn, %{"id" => appointment_id}) do
    appointment = Appointment.get_appointment!(appointment_id)
    doctors = Doctor.list_doctors()
    patients = Patient.list_patients()
    changeset = Appointment.change_appointment(appointment)
    
    render(conn, :edit_appointment, 
      page_title: "Edit Appointment", 
      appointment: appointment, 
      changeset: changeset,
      doctors: doctors,
      patients: patients
    )
  end

  def update_appointment(conn, %{"id" => appointment_id, "appointment" => appointment_params}) do
    appointment = Appointment.get_appointment!(appointment_id)

    case Appointment.update_appointment(appointment, appointment_params) do
      {:ok, _appointment} ->
        conn
        |> put_flash(:info, "Appointment updated successfully.")
        |> redirect(to: ~p"/admin_bypass/appointments")

      {:error, %Ecto.Changeset{} = changeset} ->
        doctors = Doctor.list_doctors()
        patients = Patient.list_patients()
        render(conn, :edit_appointment, 
          page_title: "Edit Appointment", 
          appointment: appointment, 
          changeset: changeset,
          doctors: doctors,
          patients: patients
        )
    end
  end

  def delete_appointment(conn, %{"id" => appointment_id}) do
    appointment = Appointment.get_appointment!(appointment_id)
    {:ok, _} = Appointment.delete_appointment(appointment)

    conn
    |> put_flash(:info, "Appointment deleted successfully.")
    |> redirect(to: ~p"/admin_bypass/appointments")
  end

  # Database seeding
  def seed_database(conn, _params) do
    case Seeder.seed() do
      :ok ->
        conn
        |> put_flash(:info, "Database seeded successfully with doctors, patients, and appointments.")
        |> redirect(to: ~p"/admin_bypass")
        
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to seed database: #{inspect(reason)}")
        |> redirect(to: ~p"/admin_bypass")
    end
  end

  # Helper functions for dashboard
  defp get_recent_activity do
    recent_appointments = Appointment.list_recent_appointments(5)
    recent_patients = Patient.list_recent_patients(3)
    recent_doctors = Doctor.list_recent_doctors(2)

    %{
      appointments: recent_appointments,
      patients: recent_patients,
      doctors: recent_doctors
    }
  end
end
