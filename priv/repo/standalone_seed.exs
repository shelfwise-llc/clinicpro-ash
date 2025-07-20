#!/usr/bin/env elixir

# This script is a truly standalone seeder that bypasses the Ash framework and Mix
# It directly connects to the database, creates tables if needed, and seeds data
# This allows us to proceed with development while the AshAuthentication issues are addressed separately

# Add required dependencies to code path
Code.append_path("_build/dev/lib/ecto/ebin")
Code.append_path("_build/dev/lib/ecto_sql/ebin")
Code.append_path("_build/dev/lib/postgrex/ebin")
Code.append_path("_build/dev/lib/db_connection/ebin")
Code.append_path("_build/dev/lib/decimal/ebin")
Code.append_path("_build/dev/lib/connection/ebin")
Code.append_path("_build/dev/lib/telemetry/ebin")
Code.append_path("_build/dev/lib/bcrypt_elixir/ebin")
Code.append_path("_build/dev/lib/comeonin/ebin")
Code.append_path("_build/dev/lib/elixir_make/ebin")
Code.append_path("_build/dev/lib/jason/ebin")

# Start the required applications
Application.ensure_all_started(:ecto)
Application.ensure_all_started(:ecto_sql)
Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:bcrypt_elixir)

# Define the repo module
defmodule StandaloneRepo do
  use Ecto.Repo,
    otp_app: :standalone,
    adapter: Ecto.Adapters.Postgres
end

# Configure the repo
Application.put_env(:standalone, StandaloneRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "clinicpro_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
)

# Start the repo
{:ok, _} = StandaloneRepo.start_link()

# Import Ecto Query
import Ecto.Query

# Define schemas
defmodule Admin do
  use Ecto.Schema
  import Ecto.Changeset

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

defmodule Doctor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "doctors" do
    field :first_name, :string
    field :last_name, :string
    field :specialty, :string
    field :email, :string
    field :phone, :string
    field :active, :boolean, default: true
    field :bio, :string
    field :profile_image, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [:first_name, :last_name, :specialty, :email, :phone, :active, :bio, :profile_image])
    |> validate_required([:first_name, :last_name, :specialty, :email, :phone])
    |> unique_constraint(:email)
  end
end

defmodule Patient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patients" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :date_of_birth, :date
    field :gender, :string
    field :active, :boolean, default: true
    field :medical_history, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :date_of_birth, :gender, :active, :medical_history])
    |> validate_required([:first_name, :last_name, :email, :phone, :date_of_birth, :gender])
    |> unique_constraint(:email)
  end
end

defmodule Appointment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appointments" do
    field :doctor_id, :binary_id
    field :patient_id, :binary_id
    field :date, :date
    field :start_time, :time
    field :end_time, :time
    field :status, :string, default: "scheduled"
    field :reason, :string
    field :notes, :string
    field :diagnosis, :string
    field :treatment, :string
    field :follow_up, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:doctor_id, :patient_id, :date, :start_time, :end_time, :status, :reason, :notes, :diagnosis, :treatment, :follow_up])
    |> validate_required([:doctor_id, :patient_id, :date, :start_time, :end_time, :status, :reason])
  end
end

# Create tables if they don't exist
StandaloneRepo.query!("""
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
""")

StandaloneRepo.query!("""
CREATE TABLE IF NOT EXISTS admins (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL,
  password_hash text NOT NULL,
  active boolean DEFAULT true,
  inserted_at timestamp(0) NOT NULL DEFAULT NOW(),
  updated_at timestamp(0) NOT NULL DEFAULT NOW()
);
""")

StandaloneRepo.query!("""
CREATE TABLE IF NOT EXISTS doctors (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  specialty text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text NOT NULL,
  active boolean DEFAULT true,
  bio text,
  profile_image text,
  inserted_at timestamp(0) NOT NULL DEFAULT NOW(),
  updated_at timestamp(0) NOT NULL DEFAULT NOW()
);
""")

StandaloneRepo.query!("""
CREATE TABLE IF NOT EXISTS patients (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text NOT NULL,
  date_of_birth date NOT NULL,
  gender text NOT NULL,
  active boolean DEFAULT true,
  medical_history text,
  inserted_at timestamp(0) NOT NULL DEFAULT NOW(),
  updated_at timestamp(0) NOT NULL DEFAULT NOW()
);
""")

StandaloneRepo.query!("""
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id uuid NOT NULL REFERENCES doctors(id),
  patient_id uuid NOT NULL REFERENCES patients(id),
  date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  status text NOT NULL DEFAULT 'scheduled',
  reason text NOT NULL,
  notes text,
  diagnosis text,
  treatment text,
  follow_up text,
  inserted_at timestamp(0) NOT NULL DEFAULT NOW(),
  updated_at timestamp(0) NOT NULL DEFAULT NOW()
);
""")

# Seed admin user
admin_params = %{
  name: "Admin User",
  email: "admin@clinicpro.com",
  role: "admin",
  password: "password123",
  active: true
}

case StandaloneRepo.get_by(Admin, email: admin_params.email) do
  nil ->
    %Admin{}
    |> Admin.changeset(admin_params)
    |> StandaloneRepo.insert!()
    IO.puts("Admin user created: #{admin_params.email}")
  _admin ->
    IO.puts("Admin user already exists: #{admin_params.email}")
end

# Seed doctors
doctors = [
  %{
    first_name: "John",
    last_name: "Smith",
    specialty: "Cardiology",
    email: "john.smith@clinicpro.com",
    phone: "555-123-4567",
    active: true,
    bio: "Dr. Smith is a cardiologist with over 15 years of experience.",
    profile_image: "doctor1.jpg"
  },
  %{
    first_name: "Sarah",
    last_name: "Johnson",
    specialty: "Pediatrics",
    email: "sarah.johnson@clinicpro.com",
    phone: "555-234-5678",
    active: true,
    bio: "Dr. Johnson specializes in pediatric care and has been practicing for 10 years.",
    profile_image: "doctor2.jpg"
  },
  %{
    first_name: "Michael",
    last_name: "Williams",
    specialty: "Orthopedics",
    email: "michael.williams@clinicpro.com",
    phone: "555-345-6789",
    active: true,
    bio: "Dr. Williams is an orthopedic surgeon with expertise in sports injuries.",
    profile_image: "doctor3.jpg"
  }
]

created_doctors = Enum.map(doctors, fn doctor_params ->
  case StandaloneRepo.get_by(Doctor, email: doctor_params.email) do
    nil ->
      doctor = %Doctor{}
      |> Doctor.changeset(doctor_params)
      |> StandaloneRepo.insert!()
      IO.puts("Doctor created: #{doctor_params.first_name} #{doctor_params.last_name}")
      doctor
    doctor ->
      IO.puts("Doctor already exists: #{doctor_params.first_name} #{doctor_params.last_name}")
      doctor
  end
end)

# Seed patients
patients = [
  %{
    first_name: "Alice",
    last_name: "Brown",
    email: "alice.brown@example.com",
    phone: "555-456-7890",
    date_of_birth: ~D[1985-04-15],
    gender: "female",
    active: true,
    medical_history: "No significant medical history."
  },
  %{
    first_name: "Robert",
    last_name: "Davis",
    email: "robert.davis@example.com",
    phone: "555-567-8901",
    date_of_birth: ~D[1978-09-22],
    gender: "male",
    active: true,
    medical_history: "Hypertension, controlled with medication."
  },
  %{
    first_name: "Emily",
    last_name: "Wilson",
    email: "emily.wilson@example.com",
    phone: "555-678-9012",
    date_of_birth: ~D[1990-12-03],
    gender: "female",
    active: true,
    medical_history: "Asthma, uses inhaler as needed."
  }
]

created_patients = Enum.map(patients, fn patient_params ->
  case StandaloneRepo.get_by(Patient, email: patient_params.email) do
    nil ->
      patient = %Patient{}
      |> Patient.changeset(patient_params)
      |> StandaloneRepo.insert!()
      IO.puts("Patient created: #{patient_params.first_name} #{patient_params.last_name}")
      patient
    patient ->
      IO.puts("Patient already exists: #{patient_params.first_name} #{patient_params.last_name}")
      patient
  end
end)

# Seed appointments
appointments = [
  %{
    doctor_id: Enum.at(created_doctors, 0).id,
    patient_id: Enum.at(created_patients, 0).id,
    date: ~D[2023-06-15],
    start_time: ~T[09:00:00],
    end_time: ~T[09:30:00],
    status: "completed",
    reason: "Annual checkup",
    notes: "Patient reported feeling well overall.",
    diagnosis: "Healthy, no concerns",
    treatment: "Continue current lifestyle",
    follow_up: "Next year"
  },
  %{
    doctor_id: Enum.at(created_doctors, 1).id,
    patient_id: Enum.at(created_patients, 1).id,
    date: ~D[2023-06-16],
    start_time: ~T[10:00:00],
    end_time: ~T[10:30:00],
    status: "scheduled",
    reason: "Blood pressure check",
    notes: nil,
    diagnosis: nil,
    treatment: nil,
    follow_up: nil
  },
  %{
    doctor_id: Enum.at(created_doctors, 2).id,
    patient_id: Enum.at(created_patients, 2).id,
    date: ~D[2023-06-17],
    start_time: ~T[11:00:00],
    end_time: ~T[11:30:00],
    status: "scheduled",
    reason: "Asthma follow-up",
    notes: nil,
    diagnosis: nil,
    treatment: nil,
    follow_up: nil
  }
]

Enum.each(appointments, fn appointment_params ->
  # Check if appointment already exists
  query = from a in Appointment,
          where: a.doctor_id == ^appointment_params.doctor_id and
                 a.patient_id == ^appointment_params.patient_id and
                 a.date == ^appointment_params.date and
                 a.start_time == ^appointment_params.start_time

  case StandaloneRepo.one(query) do
    nil ->
      %Appointment{}
      |> Appointment.changeset(appointment_params)
      |> StandaloneRepo.insert!()
      IO.puts("Appointment created for #{appointment_params.date} at #{appointment_params.start_time}")
    _appointment ->
      IO.puts("Appointment already exists for #{appointment_params.date} at #{appointment_params.start_time}")
  end
end)

IO.puts("\nSeeding completed successfully!")
