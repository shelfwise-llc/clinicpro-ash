defmodule Clinicpro.AdminBypass.Seeder do
  @moduledoc """
  A module for seeding the database with initial data using direct Ecto operations.
  This bypasses Ash APIs to avoid compilation issues with AshAuthentication.
  """

  alias Clinicpro.AdminBypass.{Doctor, Patient, Appointment}
  alias Clinicpro.Repo

  @doc """
  Seeds the database with sample doctors, patients, and appointments.
  """
  def seed do
    # Clear existing data
    Repo.delete_all(Appointment)
    Repo.delete_all(Patient)
    Repo.delete_all(Doctor)

    # Seed doctors
    {:ok, doctor1} = create_doctor("John", "Smith", "cardiology")
    {:ok, doctor2} = create_doctor("Sarah", "Johnson", "neurology")
    {:ok, doctor3} = create_doctor("Michael", "Brown", "pediatrics")

    # Seed patients
    {:ok, patient1} = create_patient("Alice", "Williams", "1990-05-15", "female")
    {:ok, patient2} = create_patient("Bob", "Davis", "1985-10-20", "male")
    {:ok, patient3} = create_patient("Carol", "Miller", "1978-03-08", "female")
    {:ok, patient4} = create_patient("David", "Wilson", "1995-12-03", "male")

    # Seed appointments
    create_appointment(doctor1, patient1, "2025-08-01", "09:00:00", "09:30:00", "scheduled", "Annual checkup")
    create_appointment(doctor2, patient2, "2025-08-02", "10:00:00", "10:30:00", "scheduled", "Headache consultation")
    create_appointment(doctor3, patient3, "2025-08-03", "11:00:00", "11:30:00", "scheduled", "Child vaccination")
    create_appointment(doctor1, patient4, "2025-08-04", "14:00:00", "14:30:00", "scheduled", "Heart examination")
    create_appointment(doctor2, patient1, "2025-08-05", "15:00:00", "15:30:00", "scheduled", "Follow-up")

    :ok
  end

  defp create_doctor(first_name, last_name, specialty) do
    Doctor.create_doctor(%{
      first_name: first_name,
      last_name: last_name,
      email: String.downcase("#{first_name}.#{last_name}@example.com"),
      phone: "555-#{:rand.uniform(999)}-#{:rand.uniform(9999)}",
      specialty: specialty,
      bio: "Experienced #{specialty} specialist with over #{:rand.uniform(20)} years of practice.",
      active: true,
      years_of_experience: :rand.uniform(20) + 5,
      consultation_fee: Decimal.new(:rand.uniform(200) + 50)
    })
  end

  defp create_patient(first_name, last_name, dob, gender) do
    Patient.create_patient(%{
      first_name: first_name,
      last_name: last_name,
      email: String.downcase("#{first_name}.#{last_name}@example.com"),
      phone: "555-#{:rand.uniform(999)}-#{:rand.uniform(9999)}",
      date_of_birth: Date.from_iso8601!(dob),
      gender: gender,
      medical_history: "Patient has a history of #{Enum.random(["asthma", "diabetes", "hypertension", "none"])}.",
      active: true
    })
  end

  defp create_appointment(doctor, patient, date, start_time, end_time, status, reason) do
    Appointment.create_appointment(%{
      doctor_id: doctor.id,
      patient_id: patient.id,
      date: Date.from_iso8601!(date),
      start_time: Time.from_iso8601!(start_time),
      end_time: Time.from_iso8601!(end_time),
      status: status,
      reason: reason,
      notes: "Initial consultation for #{reason}."
    })
  end
end
