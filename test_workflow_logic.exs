# This script tests the core workflow logic without requiring Phoenix or Ash dependencies
# Start ExUnit
ExUnit.start()

defmodule WorkflowLogicTest do
  use ExUnit.Case
  
  # Define workflow steps
  @doctor_flow_steps [
    :list_appointments,
    :access_appointment,
    :fill_medical_details,
    :record_diagnosis,
    :complete_appointment
  ]
  
  @patient_flow_steps [
    :receive_link,
    :view_appointment,
    :confirm_appointment,
    :complete_booking
  ]
  
  @guest_booking_steps [
    :search_clinics,
    :select_clinic,
    :select_doctor,
    :select_time,
    :provide_details,
    :confirm_booking
  ]
  
  # Mock data
  @mock_doctor %{
    id: "user-123",
    email: "doctor@example.com",
    role: :doctor,
    doctor: %{
      id: "doctor-123",
      first_name: "John",
      last_name: "Smith",
      specialty: "General Medicine",
      clinic_id: "clinic-123"
    }
  }
  
  @mock_appointment %{
    id: "appt-456",
    doctor_id: "doctor-123",
    patient_id: "patient-789",
    patient: %{
      id: "patient-789",
      first_name: "Jane",
      last_name: "Doe",
      date_of_birth: ~D[1990-01-01]
    },
    date: "2025-07-25",
    time: "10:00 AM",
    type: "Consultation",
    status: "scheduled"
  }
  
  # Test the doctor workflow
  describe "doctor workflow" do
    test "workflow steps are in the correct order" do
      # Verify the steps
      assert length(@doctor_flow_steps) == 5
      assert Enum.at(@doctor_flow_steps, 0) == :list_appointments
      assert Enum.at(@doctor_flow_steps, 1) == :access_appointment
      assert Enum.at(@doctor_flow_steps, 2) == :fill_medical_details
      assert Enum.at(@doctor_flow_steps, 3) == :record_diagnosis
      assert Enum.at(@doctor_flow_steps, 4) == :complete_appointment
    end
    
    test "workflow state transitions correctly" do
      # Initial state
      initial_state = %{
        workflow_type: :doctor_flow,
        current_step: :list_appointments,
        started_at: DateTime.utc_now()
      }
      
      # Simulate advancing to the next step
      next_state = advance_workflow(initial_state)
      assert next_state.current_step == :access_appointment
      
      # Simulate advancing again
      next_state = advance_workflow(next_state)
      assert next_state.current_step == :fill_medical_details
      
      # Simulate advancing again
      next_state = advance_workflow(next_state)
      assert next_state.current_step == :record_diagnosis
      
      # Simulate advancing to completion
      next_state = advance_workflow(next_state)
      assert next_state.current_step == :complete_appointment
    end
    
    test "appointment data is preserved across workflow steps" do
      # Initial state with appointment data
      state = %{
        workflow_type: :doctor_flow,
        current_step: :access_appointment,
        appointment_data: @mock_appointment,
        started_at: DateTime.utc_now()
      }
      
      # Verify appointment data
      assert state.appointment_data.id == "appt-456"
      assert state.appointment_data.patient.first_name == "Jane"
      
      # Simulate adding medical details
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }
      
      state = Map.put(state, :medical_details, medical_details)
      state = advance_workflow(state)
      
      # Verify medical details are preserved
      assert state.medical_details["height"] == "170"
      assert state.medical_details["notes"] == "Patient appears healthy"
      
      # Simulate adding diagnosis
      diagnosis = %{
        "diagnosis" => "Common cold",
        "treatment" => "Rest and fluids",
        "prescription" => "Paracetamol as needed"
      }
      
      state = Map.put(state, :diagnosis, diagnosis)
      state = advance_workflow(state)
      
      # Verify diagnosis is preserved
      assert state.diagnosis["diagnosis"] == "Common cold"
      assert state.diagnosis["treatment"] == "Rest and fluids"
    end
  end
  
  # Test the patient workflow
  describe "patient workflow" do
    test "workflow steps are in the correct order" do
      # Verify the steps
      assert length(@patient_flow_steps) == 4
      assert Enum.at(@patient_flow_steps, 0) == :receive_link
      assert Enum.at(@patient_flow_steps, 3) == :complete_booking
    end
    
    test "workflow state transitions correctly" do
      # Initial state
      initial_state = %{
        workflow_type: :patient_flow,
        current_step: :receive_link,
        started_at: DateTime.utc_now()
      }
      
      # Simulate advancing to the next step
      next_state = advance_workflow(initial_state)
      assert next_state.current_step == :view_appointment
      
      # Simulate advancing again
      next_state = advance_workflow(next_state)
      assert next_state.current_step == :confirm_appointment
      
      # Simulate advancing to completion
      next_state = advance_workflow(next_state)
      assert next_state.current_step == :complete_booking
    end
  end
  
  # Test the guest booking workflow
  describe "guest booking workflow" do
    test "workflow steps are in the correct order" do
      # Verify the steps
      assert length(@guest_booking_steps) == 6
      assert Enum.at(@guest_booking_steps, 0) == :search_clinics
      assert Enum.at(@guest_booking_steps, 5) == :confirm_booking
    end
    
    test "workflow state transitions correctly" do
      # Initial state
      initial_state = %{
        workflow_type: :guest_booking,
        current_step: :search_clinics,
        started_at: DateTime.utc_now()
      }
      
      # Simulate advancing through all steps
      state = initial_state
      
      # Check each step individually
      assert state.current_step == :search_clinics
      
      state = advance_workflow(state)
      assert state.current_step == :select_clinic
      
      state = advance_workflow(state)
      assert state.current_step == :select_doctor
      
      state = advance_workflow(state)
      assert state.current_step == :select_time
      
      state = advance_workflow(state)
      assert state.current_step == :provide_details
      
      state = advance_workflow(state)
      assert state.current_step == :confirm_booking
      
      # The last step should remain at confirm_booking
      state = advance_workflow(state)
      assert state.current_step == :confirm_booking
    end
  end
  
  # Helper function to simulate workflow advancement
  defp advance_workflow(state) do
    next_step = case {state.workflow_type, state.current_step} do
      # Doctor flow
      {:doctor_flow, :list_appointments} -> :access_appointment
      {:doctor_flow, :access_appointment} -> :fill_medical_details
      {:doctor_flow, :fill_medical_details} -> :record_diagnosis
      {:doctor_flow, :record_diagnosis} -> :complete_appointment
      {:doctor_flow, :complete_appointment} -> :complete_appointment # Terminal state
      
      # Patient flow
      {:patient_flow, :receive_link} -> :view_appointment
      {:patient_flow, :view_appointment} -> :confirm_appointment
      {:patient_flow, :confirm_appointment} -> :complete_booking
      {:patient_flow, :complete_booking} -> :complete_booking # Terminal state
      
      # Guest booking flow
      {:guest_booking, :search_clinics} -> :select_clinic
      {:guest_booking, :select_clinic} -> :select_doctor
      {:guest_booking, :select_doctor} -> :select_time
      {:guest_booking, :select_time} -> :provide_details
      {:guest_booking, :provide_details} -> :confirm_booking
      {:guest_booking, :confirm_booking} -> :confirm_booking # Terminal state
      
      # Default
      _ -> state.current_step
    end
    
    %{state | current_step: next_step}
  end
end

# Run the tests
ExUnit.run()
