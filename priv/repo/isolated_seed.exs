# Isolated seeding script that bypasses the entire application code
# This script connects directly to the database and inserts records

# Connect to the database
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

# Define the repo module
defmodule IsolatedRepo do
  use Ecto.Repo,
    otp_app: :clinicpro,
    adapter: Ecto.Adapters.Postgres
end

# Configure the repo
config = [
  database: "clinicpro_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
]

# Start the repo
{:ok, _pid} = IsolatedRepo.start_link(config)

# Define the Admin schema
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
    # Use Bcrypt directly
    hash = :crypto.hash(:sha256, password) |> Base.encode16() |> String.downcase()
    put_change(changeset, :password_hash, hash)
  end
  
  defp put_password_hash(changeset), do: changeset
end

# Define the Doctor schema
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

# Define the Patient schema
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

# Define the Appointment schema
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

# Check if tables exist, if not create them
import Ecto.Query, only: [from: 2]

# Create admin table if it doesn't exist
unless IsolatedRepo.query!("SELECT to_regclass('admins')").rows == [["admins"]] do
  IO.puts("Creating admins table...")
  IsolatedRepo.query!("""
  CREATE TABLE admins (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    is_active boolean DEFAULT true,
    inserted_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now()
  )
  """)
end

# Create doctors table if it doesn't exist
unless IsolatedRepo.query!("SELECT to_regclass('doctors')").rows == [["doctors"]] do
  IO.puts("Creating doctors table...")
  IsolatedRepo.query!("""
  CREATE TABLE doctors (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name text NOT NULL,
    last_name text NOT NULL,
    specialty text NOT NULL,
    email text NOT NULL UNIQUE,
    phone text,
    active boolean DEFAULT true,
    inserted_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now()
  )
  """)
end

# Create patients table if it doesn't exist
unless IsolatedRepo.query!("SELECT to_regclass('patients')").rows == [["patients"]] do
  IO.puts("Creating patients table...")
  IsolatedRepo.query!("""
  CREATE TABLE patients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name text NOT NULL,
    last_name text NOT NULL,
    email text NOT NULL UNIQUE,
    phone text NOT NULL,
    date_of_birth date,
    active boolean DEFAULT true,
    inserted_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now()
  )
  """)
end

# Create appointments table if it doesn't exist
unless IsolatedRepo.query!("SELECT to_regclass('appointments')").rows == [["appointments"]] do
  IO.puts("Creating appointments table...")
  IsolatedRepo.query!("""
  CREATE TABLE appointments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scheduled_date date NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    reason text,
    notes text,
    status text DEFAULT 'scheduled',
    cancelled boolean DEFAULT false,
    doctor_id uuid REFERENCES doctors(id),
    patient_id uuid REFERENCES patients(id),
    inserted_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now()
  )
  """)
end

# Create admin user if it doesn't exist
admin_email = "admin@clinicpro.com"
admin_exists = IsolatedRepo.exists?(from a in Admin, where: a.email == ^admin_email)

unless admin_exists do
  %Admin{}
  |> Admin.changeset(%{
    email: admin_email,
    password: "admin123", # This will be hashed by the changeset
    first_name: "Admin",
    last_name: "User",
    is_active: true
  })
  |> IsolatedRepo.insert!()
  
  IO.puts("Admin user created successfully")
else
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
  doctor_email = doctor_attrs.email
  doctor_exists = IsolatedRepo.exists?(from d in Doctor, where: d.email == ^doctor_email)
  
  if doctor_exists do
    doctor = IsolatedRepo.one!(from d in Doctor, where: d.email == ^doctor_email)
    IO.puts("Doctor #{doctor.first_name} #{doctor.last_name} already exists")
    doctor
  else
    doctor = %Doctor{}
    |> Doctor.changeset(doctor_attrs)
    |> IsolatedRepo.insert!()
    
    IO.puts("Doctor #{doctor.first_name} #{doctor.last_name} created successfully")
    doctor
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
  patient_email = patient_attrs.email
  patient_exists = IsolatedRepo.exists?(from p in Patient, where: p.email == ^patient_email)
  
  if patient_exists do
    patient = IsolatedRepo.one!(from p in Patient, where: p.email == ^patient_email)
    IO.puts("Patient #{patient.first_name} #{patient.last_name} already exists")
    patient
  else
    patient = %Patient{}
    |> Patient.changeset(patient_attrs)
    |> IsolatedRepo.insert!()
    
    IO.puts("Patient #{patient.first_name} #{patient.last_name} created successfully")
    patient
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
  appointment_exists = IsolatedRepo.exists?(
    from a in Appointment,
    where: a.doctor_id == ^appointment_attrs.doctor_id and
           a.patient_id == ^appointment_attrs.patient_id and
           a.scheduled_date == ^appointment_attrs.scheduled_date and
           a.start_time == ^appointment_attrs.start_time
  )
  
  unless appointment_exists do
    appointment = %Appointment{}
    |> Appointment.changeset(appointment_attrs)
    |> IsolatedRepo.insert!()
    
    doctor = Enum.find(doctors, fn d -> d.id == appointment.doctor_id end)
    patient = Enum.find(patients, fn p -> p.id == appointment.patient_id end)
    
    IO.puts("Appointment created for Dr. #{doctor.last_name} with #{patient.first_name} #{patient.last_name} on #{appointment.scheduled_date}")
  else
    IO.puts("Appointment already exists for this doctor, patient, date and time")
  end
end)

IO.puts("\nIsolated seeding completed successfully!")
