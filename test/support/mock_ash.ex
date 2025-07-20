defmodule Clinicpro.MockAsh do
  @moduledoc """
  Mock implementations of Ash-related contexts for testing.
  
  This module provides mock implementations of Ash resource functions
  to allow controller tests to run without real Ash resource compilation.
  """
  
  defmodule Appointments do
    @moduledoc """
    Mock implementation of Appointments context.
    """
    @behaviour Clinicpro.MockAsh.AppointmentsBehaviour
    
    @impl true
    def get_appointment(id) do
      %{
        id: id,
        patient_id: "patient-123",
        doctor_id: "doctor-123",
        clinic_id: "clinic-123",
        scheduled_date: ~D[2023-06-15],
        scheduled_time: ~T[14:30:00],
        status: :scheduled,
        reason: "Annual checkup",
        notes: "Patient has history of high blood pressure"
      }
    end
    
    @impl true
    def list_appointments(doctor_id) do
      [
        %{
          id: "appt-456",
          patient_id: "patient-123",
          doctor_id: doctor_id,
          clinic_id: "clinic-123",
          scheduled_date: ~D[2023-06-15],
          scheduled_time: ~T[14:30:00],
          status: :scheduled,
          reason: "Annual checkup",
          notes: "Patient has history of high blood pressure",
          patient: %{
            first_name: "John",
            last_name: "Doe"
          }
        },
        %{
          id: "appt-789",
          patient_id: "patient-456",
          doctor_id: doctor_id,
          clinic_id: "clinic-123",
          scheduled_date: ~D[2023-06-16],
          scheduled_time: ~T[10:00:00],
          status: :scheduled,
          reason: "Follow-up",
          notes: "Review test results",
          patient: %{
            first_name: "Jane",
            last_name: "Smith"
          }
        }
      ]
    end
    
    @impl true
    def create_appointment(attrs) do
      appointment = Map.merge(%{
        id: "appt-" <> Ecto.UUID.generate(),
        status: :scheduled
      }, attrs)
      
      {:ok, appointment}
    end
    
    @impl true
    def update_appointment(id, attrs) do
      appointment = get_appointment(id)
      updated = Map.merge(appointment, attrs)
      
      {:ok, updated}
    end
  end
  
  defmodule Patients do
    @moduledoc """
    Mock implementation of Patients context.
    """
    @behaviour Clinicpro.MockAsh.PatientsBehaviour
    
    @impl true
    def get_patient(id) do
      %{
        id: id,
        first_name: "John",
        last_name: "Doe",
        email: "john.doe@example.com",
        phone: "555-123-4567",
        date_of_birth: ~D[1980-01-01],
        address: "123 Main St, Anytown, USA"
      }
    end
    
    @impl true
    def list_patients do
      [
        get_patient("patient-123"),
        %{
          id: "patient-456",
          first_name: "Jane",
          last_name: "Smith",
          email: "jane.smith@example.com",
          phone: "555-987-6543",
          date_of_birth: ~D[1985-05-15],
          address: "456 Oak St, Anytown, USA"
        }
      ]
    end
    
    @impl true
    def create_patient(attrs) do
      patient = Map.merge(%{
        id: "patient-" <> Ecto.UUID.generate()
      }, attrs)
      
      {:ok, patient}
    end
    
    @impl true
    def update_patient(id, attrs) do
      patient = get_patient(id)
      updated = Map.merge(patient, attrs)
      
      {:ok, updated}
    end
    
    def create_medical_record(attrs) do
      {:ok, %{
        id: "record-" <> Ecto.UUID.generate(),
        patient_id: attrs[:patient_id] || "patient-123",
        doctor_id: attrs[:doctor_id] || "doctor-123",
        diagnosis: attrs[:diagnosis] || "Routine checkup",
        treatment: attrs[:treatment] || "Rest and fluids",
        notes: attrs[:notes] || "Patient is in good health",
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }}
    end
  end
  
  defmodule Clinics do
    @moduledoc """
    Mock implementation of Clinics context.
    """
    @behaviour Clinicpro.MockAsh.ClinicsBehaviour
    
    @impl true
    def get_clinic(id) do
      %{
        id: id,
        name: "Main Street Clinic",
        address: "456 Main St, Anytown, USA",
        phone: "555-987-6543",
        email: "info@mainstreetclinic.com"
      }
    end
    
    @impl true
    def list_clinics do
      [
        get_clinic("clinic-123"),
        %{
          id: "clinic-456",
          name: "Downtown Medical Center",
          address: "789 Broadway, Anytown, USA",
          phone: "555-456-7890",
          email: "info@downtownmedical.com"
        }
      ]
    end
    
    @impl true
    def create_clinic(attrs) do
      clinic = Map.merge(%{
        id: "clinic-" <> Ecto.UUID.generate()
      }, attrs)
      
      {:ok, clinic}
    end
    
    @impl true
    def update_clinic(id, attrs) do
      clinic = get_clinic(id)
      updated = Map.merge(clinic, attrs)
      
      {:ok, updated}
    end
    
    def list_doctors_by_clinic(clinic_id) do
      [
        %{
          id: "doctor-123",
          user_id: "user-123",
          clinic_id: clinic_id,
          specialty: "General Medicine",
          first_name: "John",
          last_name: "Smith",
          email: "john.smith@example.com"
        },
        %{
          id: "doctor-456",
          user_id: "user-456",
          clinic_id: clinic_id,
          specialty: "Cardiology",
          first_name: "Sarah",
          last_name: "Johnson",
          email: "sarah.johnson@example.com"
        }
      ]
    end
  end
end
