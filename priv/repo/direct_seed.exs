# Direct seeding script that bypasses Ash framework entirely
# This script uses Ecto directly to insert records into the database

alias Clinicpro.Repo
alias Ecto.Changeset

# Define schemas directly based on database tables
defmodule Admin do
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "admins" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :first_name, :string
    field :last_name, :string
    field :is_active, :boolean, default: true
    
    timestamps()
  end
  
  def changeset(admin, attrs) do
    admin
    |> cast(attrs, [:email, :password, :first_name, :last_name, :is_active])
    |> validate_required([:email, :password, :first_name, :last_name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_password_hash()
  end
  
  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end
  
  defp put_password_hash(changeset), do: changeset
end

defmodule Doctor do
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "doctors" do
    field :first_name, :string
    field :last_name, :string
    field :specialty, :string
    field :email, :string
    field :phone, :string
    field :active, :boolean, default: true
    
    has_many :appointments, Appointment
    
    timestamps()
  end
  
  def changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [:first_name, :last_name, :specialty, :email, :phone, :active])
    |> validate_required([:first_name, :last_name, :specialty, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end

defmodule Patient do
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "patients" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :date_of_birth, :date
    field :active, :boolean, default: true
    
    has_many :appointments, Appointment
    
    timestamps()
  end
  
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :date_of_birth, :active])
    |> validate_required([:first_name, :last_name, :email, :phone])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end

defmodule Appointment do
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "appointments" do
    field :scheduled_date, :date
    field :start_time, :time
    field :end_time, :time
    field :reason, :string
    field :notes, :string
    field :status, :string, default: "scheduled"
    field :cancelled, :boolean, default: false
    
    belongs_to :doctor, Doctor, type: :binary_id
    belongs_to :patient, Patient, type: :binary_id
    
    timestamps()
  end
  
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:scheduled_date, :start_time, :end_time, :reason, :notes, :status, :cancelled, :doctor_id, :patient_id])
    |> validate_required([:scheduled_date, :start_time, :end_time, :doctor_id, :patient_id])
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:patient_id)
  end
end

# Create admin user if it doesn't exist
case Repo.get_by(Admin, email: "admin@clinicpro.com") do
  nil ->
    # Create admin with hashed password
    %Admin{}
    |> Admin.changeset(%{
      email: "admin@clinicpro.com",
      password: "admin123", # This will be hashed by the changeset
      first_name: "Admin",
      last_name: "User",
      is_active: true
    })
    |> Repo.insert!()
    
    IO.puts("Admin user created successfully")
    
  _admin ->
    IO.puts("Admin user already exists")
end

# Create sample doctors
doctor_data = [
  %{
    first_name: "John",
    last_name: "Smith",
    specialty: "Cardiology",
    email: "john.smith@clinicpro.com",
    phone: "555-123-4567",
    active: true
  },
  %{
    first_name: "Sarah",
    last_name: "Johnson",
    specialty: "Pediatrics",
    email: "sarah.johnson@clinicpro.com",
    phone: "555-234-5678",
    active: true
  },
  %{
    first_name: "Michael",
    last_name: "Chen",
    specialty: "Neurology",
    email: "michael.chen@clinicpro.com",
    phone: "555-345-6789",
    active: true
  }
]

doctors = Enum.map(doctor_data, fn doctor_attrs ->
  case Repo.get_by(Doctor, email: doctor_attrs.email) do
    nil ->
      doctor = %Doctor{}
      |> Doctor.changeset(doctor_attrs)
      |> Repo.insert!()
      
      IO.puts("Doctor #{doctor.first_name} #{doctor.last_name} created successfully")
      doctor
      
    existing_doctor ->
      IO.puts("Doctor #{existing_doctor.first_name} #{existing_doctor.last_name} already exists")
      existing_doctor
  end
end)

# Create sample patients
patient_data = [
  %{
    first_name: "Emily",
    last_name: "Davis",
    email: "emily.davis@example.com",
    phone: "555-456-7890",
    date_of_birth: ~D[1985-04-15],
    active: true
  },
  %{
    first_name: "Robert",
    last_name: "Wilson",
    email: "robert.wilson@example.com",
    phone: "555-567-8901",
    date_of_birth: ~D[1972-09-22],
    active: true
  },
  %{
    first_name: "Jessica",
    last_name: "Brown",
    email: "jessica.brown@example.com",
    phone: "555-678-9012",
    date_of_birth: ~D[1990-12-03],
    active: true
  }
]

patients = Enum.map(patient_data, fn patient_attrs ->
  case Repo.get_by(Patient, email: patient_attrs.email) do
    nil ->
      patient = %Patient{}
      |> Patient.changeset(patient_attrs)
      |> Repo.insert!()
      
      IO.puts("Patient #{patient.first_name} #{patient.last_name} created successfully")
      patient
      
    existing_patient ->
      IO.puts("Patient #{existing_patient.first_name} #{existing_patient.last_name} already exists")
      existing_patient
  end
end)

# Create sample appointments
appointment_data = [
  %{
    scheduled_date: ~D[2023-06-15],
    start_time: ~T[09:00:00],
    end_time: ~T[09:30:00],
    reason: "Annual checkup",
    notes: "Patient has history of high blood pressure",
    status: "completed",
    cancelled: false,
    doctor_id: Enum.at(doctors, 0).id,
    patient_id: Enum.at(patients, 0).id
  },
  %{
    scheduled_date: ~D[2023-06-16],
    start_time: ~T[10:00:00],
    end_time: ~T[10:30:00],
    reason: "Flu symptoms",
    notes: "Patient reports fever and cough for 3 days",
    status: "scheduled",
    cancelled: false,
    doctor_id: Enum.at(doctors, 1).id,
    patient_id: Enum.at(patients, 1).id
  },
  %{
    scheduled_date: ~D[2023-06-17],
    start_time: ~T[14:00:00],
    end_time: ~T[14:30:00],
    reason: "Follow-up appointment",
    notes: "Review test results",
    status: "scheduled",
    cancelled: false,
    doctor_id: Enum.at(doctors, 2).id,
    patient_id: Enum.at(patients, 2).id
  }
]

Enum.each(appointment_data, fn appointment_attrs ->
  # Check if appointment already exists with same doctor, patient, date and time
  existing_appointment = Repo.get_by(Appointment, 
    doctor_id: appointment_attrs.doctor_id,
    patient_id: appointment_attrs.patient_id,
    scheduled_date: appointment_attrs.scheduled_date,
    start_time: appointment_attrs.start_time
  )
  
  if is_nil(existing_appointment) do
    appointment = %Appointment{}
    |> Appointment.changeset(appointment_attrs)
    |> Repo.insert!()
    
    doctor = Enum.find(doctors, fn d -> d.id == appointment.doctor_id end)
    patient = Enum.find(patients, fn p -> p.id == appointment.patient_id end)
    
    IO.puts("Appointment created for Dr. #{doctor.last_name} with #{patient.first_name} #{patient.last_name} on #{appointment.scheduled_date}")
  else
    IO.puts("Appointment already exists for this doctor, patient, date and time")
  end
end)

IO.puts("\nSeeding completed successfully!")
