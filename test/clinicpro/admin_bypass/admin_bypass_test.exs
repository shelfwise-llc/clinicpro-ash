#!/usr/bin/env elixir

# This script tests the admin bypass schema modules directly
# without requiring the entire Phoenix application to compile

# Add the project's ebin directory to the code path
Code.prepend_path("_build/dev/lib/clinicpro/ebin")

# Start required applications
Application.ensure_all_started(:ecto)
Application.ensure_all_started(:postgrex)

# Configure the Repo
Application.put_env(:clinicpro, Clinicpro.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "clinicpro_dev",
  hostname: "localhost",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true
)

# Start the Repo
{:ok, _unused} = Clinicpro.Repo.start_link()

# Import required modules
alias Clinicpro.AdminBypass.{Doctor, Patient, Appointment, Seeder}
alias Clinicpro.Repo

# Test function to verify schema modules
defmodule AdminBypassTest do
  def run do
    IO.puts("\n=== Testing Admin Bypass Schema Modules ===\n")

    # Test Doctor schema
    test_doctors()

    # Test Patient schema
    test_patients()

    # Test Appointment schema
    test_appointments()

    # Test Seeder
    test_seeder()
  end

  def test_doctors do
    IO.puts("Testing Doctor schema...")

    # Create a test doctor
    doctor_params = %{
      first_name: "Test",
      last_name: "Doctor",
      email: "test.doctor@example.com",
      phone: "555-123-4567",
      specialty: "Cardiology",
      bio: "Test doctor for admin bypass testing",
      active: true
    }

    # Create doctor
    case Doctor.create(doctor_params) do
      {:ok, doctor} ->
        IO.puts("✅ Created doctor: #{doctor.first_name} #{doctor.last_name}")

        # Get doctor
        case Doctor.get(doctor.id) do
          nil ->
            IO.puts("❌ Failed to get doctor by ID")

          found_doctor ->
            IO.puts("✅ Found doctor: #{found_doctor.first_name} #{found_doctor.last_name}")
        end

        # List doctors
        doctors = Doctor.list_doctors()
        IO.puts("✅ Listed #{length(doctors)} doctors")

        # List recent doctors
        recent_doctors = Doctor.list_recent_doctors(2)
        IO.puts("✅ Listed #{length(recent_doctors)} recent doctors")

        # Update doctor
        update_params = %{bio: "Updated bio for testing"}

        case Doctor.update(doctor, update_params) do
          {:ok, updated_doctor} ->
            IO.puts("✅ Updated doctor bio: #{updated_doctor.bio}")

          {:error, changeset} ->
            IO.puts("❌ Failed to update doctor: #{inspect(changeset.errors)}")
        end

        # Delete doctor
        case Doctor.delete(doctor) do
          {:ok, _unused} ->
            IO.puts("✅ Deleted doctor")

          {:error, changeset} ->
            IO.puts("❌ Failed to delete doctor: #{inspect(changeset.errors)}")
        end

      {:error, changeset} ->
        IO.puts("❌ Failed to create doctor: #{inspect(changeset.errors)}")
    end
  end

  def test_patients do
    IO.puts("\nTesting Patient schema...")

    # Create a test patient
    patient_params = %{
      first_name: "Test",
      last_name: "Patient",
      email: "test.patient@example.com",
      phone: "555-987-6543",
      date_of_birth: ~D[1990-01-01],
      gender: "female",
      medical_history: "Test patient for admin bypass testing",
      active: true
    }

    # Create patient
    case Patient.create(patient_params) do
      {:ok, patient} ->
        IO.puts("✅ Created patient: #{patient.first_name} #{patient.last_name}")

        # Get patient
        case Patient.get(patient.id) do
          nil ->
            IO.puts("❌ Failed to get patient by ID")

          found_patient ->
            IO.puts("✅ Found patient: #{found_patient.first_name} #{found_patient.last_name}")
        end

        # List patients
        patients = Patient.list_patients()
        IO.puts("✅ Listed #{length(patients)} patients")

        # List recent patients
        recent_patients = Patient.list_recent_patients(2)
        IO.puts("✅ Listed #{length(recent_patients)} recent patients")

        # Update patient
        update_params = %{medical_history: "Updated medical history for testing"}

        case Patient.update(patient, update_params) do
          {:ok, updated_patient} ->
            IO.puts("✅ Updated patient medical history: #{updated_patient.medical_history}")

          {:error, changeset} ->
            IO.puts("❌ Failed to update patient: #{inspect(changeset.errors)}")
        end

        # Delete patient
        case Patient.delete(patient) do
          {:ok, _unused} ->
            IO.puts("✅ Deleted patient")

          {:error, changeset} ->
            IO.puts("❌ Failed to delete patient: #{inspect(changeset.errors)}")
        end

      {:error, changeset} ->
        IO.puts("❌ Failed to create patient: #{inspect(changeset.errors)}")
    end
  end

  def test_appointments do
    IO.puts("\nTesting Appointment schema...")

    # Create test doctor and patient for appointment
    {:ok, doctor} =
      Doctor.create(%{
        first_name: "Appointment",
        last_name: "Doctor",
        email: "appt.doctor@example.com",
        specialty: "Neurology",
        active: true
      })

    {:ok, patient} =
      Patient.create(%{
        first_name: "Appointment",
        last_name: "Patient",
        email: "appt.patient@example.com",
        date_of_birth: ~D[1985-05-15],
        gender: "male",
        active: true
      })

    # Create a test appointment
    appointment_params = %{
      doctor_id: doctor.id,
      patient_id: patient.id,
      date: ~D[2025-08-01],
      start_time: ~T[10:00:00],
      end_time: ~T[10:30:00],
      status: "scheduled",
      reason: "Test appointment for admin bypass testing"
    }

    # Create appointment
    case Appointment.create(appointment_params) do
      {:ok, appointment} ->
        IO.puts("✅ Created appointment for #{appointment.date}")

        # Get appointment
        case Appointment.get(appointment.id) do
          nil -> IO.puts("❌ Failed to get appointment by ID")
          found_appointment -> IO.puts("✅ Found appointment for date: #{found_appointment.date}")
        end

        # List appointments
        appointments = Appointment.list_appointments()
        IO.puts("✅ Listed #{length(appointments)} appointments")

        # List appointments with associations
        appointments_with_assoc = Appointment.list_appointments_with_associations()
        IO.puts("✅ Listed #{length(appointments_with_assoc)} appointments with associations")

        # List recent appointments
        recent_appointments = Appointment.list_recent_appointments(2)
        IO.puts("✅ Listed #{length(recent_appointments)} recent appointments")

        # Update appointment
        update_params = %{status: "completed", notes: "Appointment completed successfully"}

        case Appointment.update(appointment, update_params) do
          {:ok, updated_appointment} ->
            IO.puts("✅ Updated appointment status: #{updated_appointment.status}")

          {:error, changeset} ->
            IO.puts("❌ Failed to update appointment: #{inspect(changeset.errors)}")
        end

        # Delete appointment
        case Appointment.delete(appointment) do
          {:ok, _unused} ->
            IO.puts("✅ Deleted appointment")

          {:error, changeset} ->
            IO.puts("❌ Failed to delete appointment: #{inspect(changeset.errors)}")
        end

        # Clean up
        Doctor.delete(doctor)
        Patient.delete(patient)

      {:error, changeset} ->
        IO.puts("❌ Failed to create appointment: #{inspect(changeset.errors)}")
    end
  end

  def test_seeder do
    IO.puts("\nTesting Seeder module...")

    # Run the seeder
    case Seeder.seed() do
      {:ok, results} ->
        doctor_count = length(Map.get(results, :doctors, []))
        patient_count = length(Map.get(results, :patients, []))
        appointment_count = length(Map.get(results, :appointments, []))

        IO.puts("✅ Seeded database successfully:")
        IO.puts("   - #{doctor_count} doctors")
        IO.puts("   - #{patient_count} patients")
        IO.puts("   - #{appointment_count} appointments")

        # Clean up seeded data
        Enum.each(Map.get(results, :appointments, []), fn appointment ->
          Appointment.delete(appointment)
        end)

        Enum.each(Map.get(results, :patients, []), fn patient ->
          Patient.delete(patient)
        end)

        Enum.each(Map.get(results, :doctors, []), fn doctor ->
          Doctor.delete(doctor)
        end)

        IO.puts("✅ Cleaned up seeded data")

      {:error, failed_operation, failed_value, _changes_so_far} ->
        IO.puts("❌ Failed to seed database:")
        IO.puts("   - Failed operation: #{failed_operation}")
        IO.puts("   - Failed value: #{inspect(failed_value)}")
    end
  end
end

# Run the tests
AdminBypassTest.run()
