defmodule ClinicproWeb.DoctorFlowControllerBypassTest do
  @moduledoc """
  Test module for the DoctorFlowController using our bypass approach.

  This test module uses the BypassAshForTests module to completely bypass
  the Ash authentication system and resources, allowing the tests to run
  without requiring the full Ash framework to compile.
  """
  use ClinicproWeb.ConnCase

  alias Clinicpro.BypassAshForTests.MockUser
  alias Clinicpro.BypassAshForTests.MockDoctor
  alias Clinicpro.BypassAshForTests.MockAppointment
  alias Clinicpro.BypassAshForTests.MockAuth

  # Mock data for tests
  @mock_doctor %MockUser{
    id: "user-123",
    email: "doctor@example.com",
    role: :doctor,
    doctor: %MockDoctor{
      id: "doctor-123",
      first_name: "John",
      last_name: "Smith",
      specialty: "General Medicine",
      clinic_id: "clinic-123"
    }
  }

  @mock_appointment %MockAppointment{
    id: "appt-456",
    doctor_id: "doctor-123",
    patient_id: "patient-789",
    date: "2025-07-25",
    time: "10:00 AM",
    type: "Consultation",
    status: "scheduled"
  }

  # Helper function to authenticate a user
  defp authenticate_user(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> MockAuth.sign_in(user)
  end

  # Helper function to set up workflow state
  defp setup_workflow_state(conn, workflow_type, current_step) do
    workflow_state = %{
      workflow_type: workflow_type,
      current_step: current_step,
      started_at: DateTime.utc_now()
    }

    conn
    |> Plug.Conn.put_session(:workflow_state, workflow_state)
  end

  describe "doctor workflow" do
    test "start_workflow initializes the workflow state", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAccountsAPI
      |> expect(:get_user, fn _unused -> {:ok, @mock_doctor} end)

      # Authenticate the doctor
      conn = authenticate_user(conn, @mock_doctor)

      # Call the start_workflow action
      conn = get(conn, ~p"/doctor/workflow/start")

      # Verify the response
      assert redirected_to(conn) == ~p"/doctor/appointments"

      # Verify the workflow state is initialized
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.workflow_type == :doctor_flow
      assert workflow_state.current_step == :list_appointments
    end

    test "list_appointments shows appointments for the doctor", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:list_appointments, fn _unused -> {:ok, [@mock_appointment]} end)

      # Authenticate the doctor and set up workflow state
      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> setup_workflow_state(:doctor_flow, :list_appointments)

      # Call the list_appointments action
      conn = get(conn, ~p"/doctor/appointments")

      # Verify the response
      assert html_response(conn, 200) =~ "Your Appointments"
      assert html_response(conn, 200) =~ @mock_appointment.date
    end

    test "access_appointment shows appointment details", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:get_appointment, fn _unused -> {:ok, @mock_appointment} end)

      # Authenticate the doctor and set up workflow state
      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> setup_workflow_state(:doctor_flow, :access_appointment)

      # Call the access_appointment action
      conn = get(conn, ~p"/doctor/appointments/#{@mock_appointment.id}")

      # Verify the response
      assert html_response(conn, 200) =~ "Appointment Details"
      assert html_response(conn, 200) =~ @mock_appointment.date

      # Verify the workflow state is updated
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.current_step == :fill_medical_details
      assert workflow_state.appointment_id == @mock_appointment.id
    end

    test "fill_medical_details shows the medical details form", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:get_appointment, fn _unused -> {:ok, @mock_appointment} end)

      # Authenticate the doctor and set up workflow state
      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> setup_workflow_state(:doctor_flow, :fill_medical_details)
        |> Plug.Conn.put_session(:appointment_id, @mock_appointment.id)

      # Call the fill_medical_details action
      conn = get(conn, ~p"/doctor/appointments/#{@mock_appointment.id}/medical_details")

      # Verify the response
      assert html_response(conn, 200) =~ "Medical Details"
      assert html_response(conn, 200) =~ "Height"
      assert html_response(conn, 200) =~ "Weight"
    end

    test "submit_medical_details updates the workflow state", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:get_appointment, fn _unused -> {:ok, @mock_appointment} end)
      |> expect(:update_appointment, fn _unused, _unused -> {:ok, @mock_appointment} end)

      # Authenticate the doctor and set up workflow state
      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> setup_workflow_state(:doctor_flow, :fill_medical_details)
        |> Plug.Conn.put_session(:appointment_id, @mock_appointment.id)

      # Medical details to submit
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }

      # Call the submit_medical_details action
      conn =
        post(conn, ~p"/doctor/appointments/#{@mock_appointment.id}/medical_details", %{
          "medical_details" => medical_details
        })

      # Verify the response
      assert redirected_to(conn) == ~p"/doctor/appointments/#{@mock_appointment.id}/diagnosis"

      # Verify the workflow state is updated
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.current_step == :record_diagnosis
      assert workflow_state.medical_details["height"] == "170"
    end

    test "record_diagnosis shows the diagnosis form", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:get_appointment, fn _unused -> {:ok, @mock_appointment} end)

      # Medical details from previous step
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }

      # Authenticate the doctor and set up workflow state
      workflow_state = %{
        workflow_type: :doctor_flow,
        current_step: :record_diagnosis,
        started_at: DateTime.utc_now(),
        appointment_id: @mock_appointment.id,
        medical_details: medical_details
      }

      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> Plug.Conn.put_session(:workflow_state, workflow_state)

      # Call the record_diagnosis action
      conn = get(conn, ~p"/doctor/appointments/#{@mock_appointment.id}/diagnosis")

      # Verify the response
      assert html_response(conn, 200) =~ "Diagnosis"
      assert html_response(conn, 200) =~ "Treatment Plan"
    end

    test "submit_diagnosis updates the workflow state", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:get_appointment, fn _unused -> {:ok, @mock_appointment} end)
      |> expect(:update_appointment, fn _unused, _unused -> {:ok, @mock_appointment} end)

      # Medical details from previous step
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }

      # Authenticate the doctor and set up workflow state
      workflow_state = %{
        workflow_type: :doctor_flow,
        current_step: :record_diagnosis,
        started_at: DateTime.utc_now(),
        appointment_id: @mock_appointment.id,
        medical_details: medical_details
      }

      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> Plug.Conn.put_session(:workflow_state, workflow_state)

      # Diagnosis to submit
      diagnosis = %{
        "diagnosis" => "Common cold",
        "treatment" => "Rest and fluids",
        "prescription" => "Paracetamol as needed"
      }

      # Call the submit_diagnosis action
      conn =
        post(conn, ~p"/doctor/appointments/#{@mock_appointment.id}/diagnosis", %{
          "diagnosis" => diagnosis
        })

      # Verify the response
      assert redirected_to(conn) == ~p"/doctor/appointments/#{@mock_appointment.id}/complete"

      # Verify the workflow state is updated
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.current_step == :complete_appointment
      assert workflow_state.diagnosis["diagnosis"] == "Common cold"
    end

    test "complete_appointment shows the completion page", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:get_appointment, fn _unused -> {:ok, @mock_appointment} end)

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

      # Authenticate the doctor and set up workflow state
      workflow_state = %{
        workflow_type: :doctor_flow,
        current_step: :complete_appointment,
        started_at: DateTime.utc_now(),
        appointment_id: @mock_appointment.id,
        medical_details: medical_details,
        diagnosis: diagnosis
      }

      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> Plug.Conn.put_session(:workflow_state, workflow_state)

      # Call the complete_appointment action
      conn = get(conn, ~p"/doctor/appointments/#{@mock_appointment.id}/complete")

      # Verify the response
      assert html_response(conn, 200) =~ "Appointment Completed"
      assert html_response(conn, 200) =~ "Common cold"
    end

    test "finish_appointment redirects to the appointments list", %{conn: conn} do
      # Set up mocks
      import Mox

      Clinicpro.MockAppointmentsAPI
      |> expect(:get_appointment, fn _unused -> {:ok, @mock_appointment} end)
      |> expect(:update_appointment, fn _unused, _unused ->
        {:ok, %{@mock_appointment | status: "completed"}}
      end)

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

      # Authenticate the doctor and set up workflow state
      workflow_state = %{
        workflow_type: :doctor_flow,
        current_step: :complete_appointment,
        started_at: DateTime.utc_now(),
        appointment_id: @mock_appointment.id,
        medical_details: medical_details,
        diagnosis: diagnosis
      }

      conn =
        conn
        |> authenticate_user(@mock_doctor)
        |> Plug.Conn.put_session(:workflow_state, workflow_state)

      # Call the finish_appointment action
      conn = post(conn, ~p"/doctor/appointments/#{@mock_appointment.id}/finish")

      # Verify the response
      assert redirected_to(conn) == ~p"/doctor/appointments"

      # Verify the workflow state is reset
      refute Plug.Conn.get_session(conn, :workflow_state)
    end
  end
end
