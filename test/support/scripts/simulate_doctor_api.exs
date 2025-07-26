# This script simulates API calls to the doctor flow endpoints
# without requiring the Phoenix server to be running

# Define mock structs for testing
defmodule MockUser do
  defstruct [:id, :email, :role, :doctor]
end

defmodule MockDoctor do
  defstruct [:id, :first_name, :last_name, :specialty]
end

defmodule MockPatient do
  defstruct [:id, :first_name, :last_name, :date_of_birth]
end

defmodule MockAppointment do
  defstruct [
    :id,
    :doctor_id,
    :patient_id,
    :date,
    :time,
    :type,
    :status,
    :medical_details,
    :diagnosis,
    :patient
  ]
end

# Mock workflow state management
defmodule WorkflowState do
  def new(type, step, opts \\ %{}) do
    Map.merge(
      %{
        workflow_type: type,
        current_step: step,
        started_at: DateTime.utc_now()
      },
      opts
    )
  end

  def advance(state, next_step, data \\ %{}) do
    state
    |> Map.put(:current_step, next_step)
    |> Map.merge(data)
  end
end

# Mock API client
defmodule DoctorApiClient do
  # Create test data
  def setup_test_data do
    doctor = %MockDoctor{
      id: "doctor-123",
      first_name: "John",
      last_name: "Smith",
      specialty: "General Medicine"
    }

    user = %MockUser{
      id: "user-123",
      email: "doctor@example.com",
      role: :doctor,
      doctor: doctor
    }

    patient = %MockPatient{
      id: "patient-789",
      first_name: "Jane",
      last_name: "Doe",
      date_of_birth: "1990-01-01"
    }

    appointment = %MockAppointment{
      id: "appt-456",
      doctor_id: doctor.id,
      patient_id: patient.id,
      date: "2025-07-25",
      time: "10:00 AM",
      type: "Consultation",
      status: "scheduled",
      patient: patient
    }

    workflow_state = WorkflowState.new(:doctor_flow, :list_appointments)

    %{
      user: user,
      doctor: doctor,
      patient: patient,
      appointment: appointment,
      workflow_state: workflow_state
    }
  end

  # Simulate GET /doctor/appointments
  def list_appointments(state) do
    IO.puts("\n=== GET /doctor/appointments ===")
    IO.puts("Current step: #{state.workflow_state.current_step}")

    appointments = [state.appointment]

    IO.puts("Found #{length(appointments)} appointment(s):")

    Enum.each(appointments, fn appointment ->
      IO.puts("  ID: #{appointment.id}")
      IO.puts("  Date: #{appointment.date}")
      IO.puts("  Time: #{appointment.time}")
      IO.puts("  Type: #{appointment.type}")
      IO.puts("  Status: #{appointment.status}")
      IO.puts("  Patient: #{appointment.patient.first_name} #{appointment.patient.last_name}")
    end)

    state
  end

  # Simulate GET /doctor/appointments/:id
  def view_appointment(state, appointment_id) do
    IO.puts("\n=== GET /doctor/appointments/#{appointment_id} ===")
    IO.puts("Current step: #{state.workflow_state.current_step}")

    # Update workflow state
    workflow_state =
      WorkflowState.advance(state.workflow_state, :fill_medical_details, %{
        appointment_id: appointment_id
      })

    IO.puts("Appointment details:")
    IO.puts("  ID: #{state.appointment.id}")
    IO.puts("  Date: #{state.appointment.date}")
    IO.puts("  Time: #{state.appointment.time}")
    IO.puts("  Type: #{state.appointment.type}")
    IO.puts("  Status: #{state.appointment.status}")

    IO.puts(
      "  Patient: #{state.appointment.patient.first_name} #{state.appointment.patient.last_name}"
    )

    IO.puts("\nWorkflow advanced to: #{workflow_state.current_step}")

    %{state | workflow_state: workflow_state}
  end

  # Simulate POST /doctor/medical_details/:id
  def submit_medical_details(state, appointment_id, medical_details) do
    IO.puts("\n=== POST /doctor/medical_details/#{appointment_id} ===")
    IO.puts("Current step: #{state.workflow_state.current_step}")

    # Update workflow state
    workflow_state =
      WorkflowState.advance(state.workflow_state, :record_diagnosis, %{
        medical_details: medical_details
      })

    IO.puts("Medical details submitted:")

    Enum.each(medical_details, fn {key, value} ->
      IO.puts("  #{key}: #{value}")
    end)

    IO.puts("\nWorkflow advanced to: #{workflow_state.current_step}")

    %{state | workflow_state: workflow_state}
  end

  # Simulate POST /doctor/diagnosis/:id
  def submit_diagnosis(state, appointment_id, diagnosis) do
    IO.puts("\n=== POST /doctor/diagnosis/#{appointment_id} ===")
    IO.puts("Current step: #{state.workflow_state.current_step}")

    # Update workflow state
    workflow_state =
      WorkflowState.advance(state.workflow_state, :complete_appointment, %{
        diagnosis: diagnosis
      })

    IO.puts("Diagnosis submitted:")

    Enum.each(diagnosis, fn {key, value} ->
      IO.puts("  #{key}: #{value}")
    end)

    IO.puts("\nWorkflow advanced to: #{workflow_state.current_step}")

    %{state | workflow_state: workflow_state}
  end

  # Simulate POST /doctor/complete/:id
  def complete_appointment(state, appointment_id) do
    IO.puts("\n=== POST /doctor/complete/#{appointment_id} ===")
    IO.puts("Current step: #{state.workflow_state.current_step}")

    # Update workflow state
    workflow_state = WorkflowState.advance(state.workflow_state, :completed)

    IO.puts("Appointment completed successfully!")
    IO.puts("\nWorkflow advanced to: #{workflow_state.current_step}")

    %{state | workflow_state: workflow_state}
  end
end

# Run the simulation
state = DoctorApiClient.setup_test_data()

# Simulate the entire doctor flow
state = DoctorApiClient.list_appointments(state)
state = DoctorApiClient.view_appointment(state, state.appointment.id)

medical_details = %{
  "height" => "170",
  "weight" => "70",
  "blood_pressure" => "120/80",
  "temperature" => "36.6",
  "pulse" => "72",
  "notes" => "Patient appears healthy"
}

state = DoctorApiClient.submit_medical_details(state, state.appointment.id, medical_details)

diagnosis = %{
  "diagnosis" => "Common cold",
  "treatment" => "Rest and fluids",
  "prescription" => "Paracetamol as needed"
}

state = DoctorApiClient.submit_diagnosis(state, state.appointment.id, diagnosis)

state = DoctorApiClient.complete_appointment(state, state.appointment.id)

IO.puts("\n=== Simulation Complete ===")
IO.puts("Final workflow state: #{state.workflow_state.current_step}")
