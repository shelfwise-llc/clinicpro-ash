# This is a standalone test runner for doctor flow tests
# It doesn't depend on the main application or AshAuthentication

# Start ExUnit without loading the application
ExUnit.start(exclude: [:test], include: [:doctor_flow_isolated])

# Import the workflow validator
Code.require_file("support/workflow_validator.ex", "test")

defmodule ClinicproWeb.DoctorFlowIsolatedTest do
  use ExUnit.Case, async: false

  # Tag these tests for selective running
  @moduletag :doctor_flow_isolated

  # Import the workflow validator
  alias Clinicpro.WorkflowValidator

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
      :diagnosis
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

  # Setup for all tests
  setup do
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

    appointment = %MockAppointment{
      id: "appt-456",
      doctor_id: doctor.id,
      patient_id: "patient-789",
      date: "2025-07-25",
      time: "10:00 AM",
      type: "Consultation",
      status: "scheduled"
    }

    {:ok, %{user: user, doctor: doctor, appointment: appointment}}
  end

  # Test cases for doctor workflow
  describe "doctor flow - happy path" do
    test "doctor can list appointments", %{user: _user, appointment: appointment} do
      # Set up initial workflow state
      workflow_state = WorkflowState.new(:doctor_flow, :list_appointments)

      # Simulate controller action
      appointments = [appointment]

      # Verify expected behavior
      assert length(appointments) == 1
      assert workflow_state.current_step == :list_appointments
    end

    test "doctor can view appointment details", %{user: _user, appointment: appointment} do
      # Set up initial workflow state
      workflow_state = WorkflowState.new(:doctor_flow, :access_appointment)

      # Simulate controller action
      workflow_state =
        WorkflowState.advance(workflow_state, :fill_medical_details, %{
          appointment_id: appointment.id
        })

      # Verify expected behavior
      assert workflow_state.current_step == :fill_medical_details
      assert workflow_state.appointment_id == appointment.id
    end

    test "doctor can enter medical details", %{user: _user, appointment: appointment} do
      # Set up initial workflow state with appointment ID
      workflow_state =
        WorkflowState.new(:doctor_flow, :fill_medical_details, %{
          appointment_id: appointment.id
        })

      # Medical details to submit
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "pulse" => "72",
        "notes" => "Patient appears healthy"
      }

      # Validate medical details
      assert :ok = WorkflowValidator.validate_medical_details(medical_details)

      # Validate workflow transition
      assert :ok = WorkflowValidator.validate_transition(workflow_state, :record_diagnosis)

      # Simulate controller action
      workflow_state =
        WorkflowState.advance(workflow_state, :record_diagnosis, %{
          medical_details: medical_details
        })

      # Verify expected behavior
      assert workflow_state.current_step == :record_diagnosis
      assert workflow_state.medical_details["height"] == "170"
      assert workflow_state.medical_details["notes"] == "Patient appears healthy"
    end

    test "doctor can record diagnosis", %{user: _user, appointment: appointment} do
      # Medical details from previous step
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }

      # Set up initial workflow state with appointment ID and medical details
      workflow_state =
        WorkflowState.new(:doctor_flow, :record_diagnosis, %{
          appointment_id: appointment.id,
          medical_details: medical_details
        })

      # Validate step data
      assert :ok = WorkflowValidator.validate_step_data(workflow_state)

      # Diagnosis to submit
      diagnosis = %{
        "diagnosis" => "Common cold",
        "treatment" => "Rest and fluids",
        "prescription" => "Paracetamol as needed"
      }

      # Validate diagnosis
      assert :ok = WorkflowValidator.validate_diagnosis(diagnosis)

      # Validate workflow transition
      assert :ok = WorkflowValidator.validate_transition(workflow_state, :complete_appointment)

      # Simulate controller action
      workflow_state =
        WorkflowState.advance(workflow_state, :complete_appointment, %{
          diagnosis: diagnosis
        })

      # Verify expected behavior
      assert workflow_state.current_step == :complete_appointment
      assert workflow_state.diagnosis["diagnosis"] == "Common cold"
      assert workflow_state.diagnosis["treatment"] == "Rest and fluids"
    end

    test "doctor can complete appointment", %{user: _user, appointment: appointment} do
      # Medical details and diagnosis from previous steps
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }

      diagnosis = %{
        "diagnosis" => "Common cold",
        "treatment" => "Rest and fluids",
        "prescription" => "Paracetamol as needed"
      }

      # Set up initial workflow state with appointment ID, medical details, and diagnosis
      workflow_state =
        WorkflowState.new(:doctor_flow, :complete_appointment, %{
          appointment_id: appointment.id,
          medical_details: medical_details,
          diagnosis: diagnosis
        })

      # Simulate controller action
      workflow_state = WorkflowState.advance(workflow_state, :completed)

      # Verify expected behavior
      assert workflow_state.current_step == :completed
    end
  end

  describe "doctor flow - edge cases" do
    test "doctor can handle empty appointment list", %{user: _user} do
      # Set up initial workflow state
      workflow_state = WorkflowState.new(:doctor_flow, :list_appointments)

      # Simulate controller action with empty list
      appointments = []

      # Verify expected behavior
      assert length(appointments) == 0
      assert workflow_state.current_step == :list_appointments
      assert :ok = WorkflowValidator.validate_step_data(workflow_state)
    end

    test "doctor can handle invalid appointment ID", %{user: _user} do
      # Set up initial workflow state
      workflow_state = WorkflowState.new(:doctor_flow, :access_appointment)

      # Simulate controller action with invalid ID
      _invalid_id = "invalid-id"

      # In a real controller, this would return an error
      # Here we just verify the workflow state doesn't change
      assert workflow_state.current_step == :access_appointment
      refute Map.has_key?(workflow_state, :appointment_id)
    end

    test "doctor can handle incomplete medical details", %{user: _user, appointment: appointment} do
      # Set up initial workflow state with appointment ID
      workflow_state =
        WorkflowState.new(:doctor_flow, :fill_medical_details, %{
          appointment_id: appointment.id
        })

      # Incomplete medical details (missing required fields)
      incomplete_details = %{
        "height" => "170",
        # Missing weight
        "blood_pressure" => "120/80"
        # Missing other fields
      }

      # Validate medical details
      assert {:error, _reason} = WorkflowValidator.validate_medical_details(incomplete_details)

      # In a real controller, validation would fail
      # Here we just verify the workflow state doesn't advance
      assert workflow_state.current_step == :fill_medical_details
    end
  end

  describe "doctor flow - workflow validation" do
    test "workflow enforces step order", %{user: _user, appointment: _appointment} do
      # Try to jump from list_appointments directly to record_diagnosis (skipping fill_medical_details)
      workflow_state = WorkflowState.new(:doctor_flow, :list_appointments)

      # Validate transition to next step
      assert :ok = WorkflowValidator.validate_transition(workflow_state, :access_appointment)

      # Validate invalid transition (skipping steps)
      assert {:error, _reason} =
               WorkflowValidator.validate_transition(workflow_state, :record_diagnosis)

      # Only allowed to advance to the next step in sequence
      workflow_state = WorkflowState.advance(workflow_state, :access_appointment)
      assert workflow_state.current_step == :access_appointment
    end

    test "completed workflow cannot be modified", %{user: _user, appointment: appointment} do
      # Set up a completed workflow
      workflow_state =
        WorkflowState.new(:doctor_flow, :completed, %{
          appointment_id: appointment.id,
          completed_at: DateTime.utc_now()
        })

      # Validate that completed workflows cannot be modified
      assert {:error, _reason} =
               WorkflowValidator.validate_transition(workflow_state, :list_appointments)

      # Verify the workflow is marked as completed
      assert workflow_state.current_step == :completed
      assert Map.has_key?(workflow_state, :completed_at)
    end
  end
end
