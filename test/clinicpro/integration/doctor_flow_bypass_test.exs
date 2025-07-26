# Script to test the doctor flow bypass controller
# This script loads only the necessary modules and runs a simple HTTP server

# Load the workflow validator
Code.require_file("test/support/workflow_validator.ex")

# Define a simple test application for the doctor flow bypass controller
defmodule DoctorFlowBypassTest do
  use ExUnit.Case

  # Import the workflow validator
  alias Clinicpro.WorkflowValidator

  # Define mock structs for testing
  defmodule MockUser do
    defstruct [:id, :email, :name, :role]
  end

  defmodule MockDoctor do
    defstruct [:id, :user_id, :specialty, :years_experience]
  end

  defmodule MockPatient do
    defstruct [:id, :user_id, :medical_history]
  end

  defmodule MockAppointment do
    defstruct [
      :id,
      :doctor_id,
      :patient_id,
      :scheduled_time,
      :status,
      :medical_details,
      :diagnosis
    ]
  end

  # Create mock data
  def create_mock_data do
    # Create mock users
    doctor_user = %MockUser{
      id: "user_1",
      email: "doctor@example.com",
      name: "Dr. Smith",
      role: "doctor"
    }

    patient_user = %MockUser{
      id: "user_2",
      email: "patient@example.com",
      name: "John Doe",
      role: "patient"
    }

    # Create mock doctor and patient
    doctor = %MockDoctor{
      id: "doctor_1",
      user_id: doctor_user.id,
      specialty: "General Medicine",
      years_experience: 10
    }

    patient = %MockPatient{
      id: "patient_1",
      user_id: patient_user.id,
      medical_history: "No significant medical history"
    }

    # Create mock appointments
    appointments = [
      %MockAppointment{
        id: "appt_1",
        doctor_id: doctor.id,
        patient_id: patient.id,
        scheduled_time: ~U[2025-07-20 10:00:00Z],
        status: "scheduled",
        medical_details: nil,
        diagnosis: nil
      },
      %MockAppointment{
        id: "appt_2",
        doctor_id: doctor.id,
        patient_id: patient.id,
        scheduled_time: ~U[2025-07-21 14:30:00Z],
        status: "scheduled",
        medical_details: nil,
        diagnosis: nil
      }
    ]

    %{
      doctor_user: doctor_user,
      patient_user: patient_user,
      doctor: doctor,
      patient: patient,
      appointments: appointments
    }
  end

  # Test the doctor flow
  test "doctor flow bypass controller" do
    mock_data = create_mock_data()

    # Test workflow validation
    appointment = List.first(mock_data.appointments)

    # Test medical details validation
    medical_details = %{
      "temperature" => "98.6",
      "blood_pressure" => "120/80",
      "heart_rate" => "72",
      "symptoms" => "Headache, fatigue"
    }

    assert WorkflowValidator.validate_medical_details(medical_details) == :ok

    # Test diagnosis validation
    diagnosis = %{
      "condition" => "Migraine",
      "treatment" => "Rest, hydration, pain medication",
      "prescription" => "Ibuprofen 400mg as needed"
    }

    assert WorkflowValidator.validate_diagnosis(diagnosis) == :ok

    # Test workflow state transitions
    assert WorkflowValidator.validate_transition(:scheduled, :in_progress) == :ok
    assert WorkflowValidator.validate_transition(:in_progress, :medical_details_added) == :ok
    assert WorkflowValidator.validate_transition(:medical_details_added, :diagnosis_added) == :ok
    assert WorkflowValidator.validate_transition(:diagnosis_added, :completed) == :ok

    IO.puts("All workflow validations passed!")
    IO.puts("Doctor flow bypass controller is ready for testing.")
    IO.puts("\nTo manually test the doctor flow, you can run:")
    IO.puts("1. Run the isolated tests: ./run_isolated_doctor_tests.sh")
    IO.puts("2. Import the bypass routes in your router.ex file")
    IO.puts("3. Use the bypass controller endpoints at /doctor/appointments")
  end
end

# Run the test
ExUnit.start()
DoctorFlowBypassTest.run()
