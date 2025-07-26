defmodule ClinicproWeb.DoctorFlowControllerTest do
  use ClinicproWeb.ConnCase, async: false

  # Use our controller test bypass helper
  import ClinicproWeb.ControllerTestBypass

  # Tag all tests to exclude them when AshAuthentication is problematic
  @moduletag :doctor_flow_helper

  # Mock the Ash modules to avoid compilation issues
  @moduletag :doctor_flow

  # Mock data for tests
  @mock_doctor mock_doctor()
  @mock_appointment mock_appointment()

  # Setup for all tests
  setup do
    # Configure application environment to use our mock modules
    Application.put_env(:clinicpro, :accounts_api, Clinicpro.Mocks.Accounts)
    Application.put_env(:clinicpro, :appointments_api, Clinicpro.Mocks.Appointments)
    Application.put_env(:clinicpro, :auth_module, Clinicpro.Mocks.Accounts)

    :ok
  end

  describe "doctor flow" do
    test "GET /doctor/appointments - renders appointment list", %{conn: conn} do
      # Authenticate the doctor and set up workflow state
      conn = setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :list_appointments)

      # Make the request
      conn = get(conn, ~p"/doctor/appointments")

      # Should render appointment list
      response = html_response(conn, 200)
      assert response =~ "Your Appointments"
      # The mock data should include at least one appointment
      assert response =~ "Patient Name"
    end

    test "GET /doctor/appointment/:id - renders appointment details", %{conn: conn} do
      # Authenticate the doctor and set up workflow state
      appointment_id = "appt-456"
      conn = setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :access_appointment)

      # Make the request
      conn = get(conn, ~p"/doctor/appointment/#{appointment_id}")

      # Should render appointment details
      response = html_response(conn, 200)
      assert response =~ "Appointment Details"

      # Verify the workflow state is updated
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.current_step == :fill_medical_details
      assert workflow_state.appointment_id == appointment_id
    end

    test "GET /doctor/medical-details/:id - renders medical details form", %{conn: conn} do
      # Authenticate the doctor and set up workflow state
      appointment_id = "appt-456"

      # Set up workflow state with appointment ID
      conn =
        setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :fill_medical_details, %{
          appointment_id: appointment_id
        })

      # Make the request
      conn = get(conn, ~p"/doctor/medical-details/#{appointment_id}")

      # Should render medical details form
      response = html_response(conn, 200)
      assert response =~ "Medical Details"
      assert response =~ "Height"
      assert response =~ "Weight"
      assert response =~ "Blood Pressure"
    end

    test "POST /doctor/medical-details/:id - processes medical details and advances workflow", %{
      conn: conn
    } do
      # Authenticate the doctor and set up workflow state
      appointment_id = "appt-456"

      # Set up workflow state with appointment ID
      conn =
        setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :fill_medical_details, %{
          appointment_id: appointment_id
        })

      # Medical details params
      medical_details = %{
        "height" => "180",
        "weight" => "75",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "pulse" => "72",
        "notes" => "Patient appears healthy"
      }

      # Make the request
      conn =
        post(conn, ~p"/doctor/medical-details/#{appointment_id}", %{
          "medical_details" => medical_details
        })

      # Should redirect to diagnosis page
      assert redirected_to(conn) == ~p"/doctor/diagnosis/#{appointment_id}"

      # Verify the workflow state is updated
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.current_step == :record_diagnosis
      assert workflow_state.appointment_id == appointment_id
      assert workflow_state.medical_details == medical_details
    end

    test "GET /doctor/diagnosis/:id - renders diagnosis form", %{conn: conn} do
      # Authenticate the doctor and set up workflow state
      appointment_id = "appt-456"

      # Medical details from previous step
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }

      # Set up workflow state with appointment ID and medical details
      conn =
        setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :record_diagnosis, %{
          appointment_id: appointment_id,
          medical_details: medical_details
        })

      # Make the request
      conn = get(conn, ~p"/doctor/diagnosis/#{appointment_id}")

      # Should render diagnosis form
      response = html_response(conn, 200)
      assert response =~ "Diagnosis"
      assert response =~ "Treatment Plan"
    end

    test "POST /doctor/diagnosis/:id - processes diagnosis and advances workflow", %{conn: conn} do
      # Authenticate the doctor and set up workflow state
      appointment_id = "appt-456"

      # Medical details from previous step
      medical_details = %{
        "height" => "170",
        "weight" => "70",
        "blood_pressure" => "120/80",
        "temperature" => "36.6",
        "notes" => "Patient appears healthy"
      }

      # Set up workflow state with appointment ID and medical details
      conn =
        setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :record_diagnosis, %{
          appointment_id: appointment_id,
          medical_details: medical_details
        })

      # Diagnosis to submit
      diagnosis = %{
        "diagnosis" => "Common cold",
        "treatment" => "Rest and fluids",
        "prescription" => "Paracetamol as needed"
      }

      # Make the request
      conn = post(conn, ~p"/doctor/diagnosis/#{appointment_id}", %{"diagnosis" => diagnosis})

      # Should redirect to completion page
      assert redirected_to(conn) == ~p"/doctor/complete/#{appointment_id}"

      # Verify the workflow state is updated
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.current_step == :complete_appointment
      assert workflow_state.diagnosis["diagnosis"] == "Common cold"
    end

    test "GET /doctor/save-profile/:id - renders save profile page", %{conn: conn} do
      # Authenticate the doctor and set up workflow state
      appointment_id = "appt-456"

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

      # Set up workflow state with appointment ID, medical details, and diagnosis
      conn =
        setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :complete_appointment, %{
          appointment_id: appointment_id,
          medical_details: medical_details,
          diagnosis: diagnosis
        })

      # Make the request
      conn = get(conn, ~p"/doctor/complete/#{appointment_id}")

      # Should render completion page
      response = html_response(conn, 200)
      assert response =~ "Appointment Complete"
      assert response =~ "successfully recorded"
    end

    test "POST /doctor/complete/:id - processes completion and finalizes workflow", %{conn: conn} do
      # Authenticate the doctor and set up workflow state
      appointment_id = "appt-456"

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

      # Set up workflow state with appointment ID, medical details, and diagnosis
      conn =
        setup_conn_with_user(conn, @mock_doctor, :doctor_flow, :complete_appointment, %{
          appointment_id: appointment_id,
          medical_details: medical_details,
          diagnosis: diagnosis
        })

      # Make the request with completion confirmation
      conn = post(conn, ~p"/doctor/complete/#{appointment_id}", %{"confirm" => "true"})

      # Should redirect to appointments list
      assert redirected_to(conn) == ~p"/doctor/appointments"

      # Verify the workflow state is updated to completed
      workflow_state = Plug.Conn.get_session(conn, :workflow_state)
      assert workflow_state.current_step == :completed

      # Verify the appointment was updated via the mock API
      # This would be a good place to verify Mox expectations if we want to be more strict
    end
  end
end
