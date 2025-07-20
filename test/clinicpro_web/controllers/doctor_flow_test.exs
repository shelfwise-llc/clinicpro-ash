defmodule ClinicproWeb.DoctorFlowTest do
  use ClinicproWeb.ConnCase, async: true
  
  alias Clinicpro.AuthBypass
  
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
  
  setup %{conn: conn} do
    # Set up a connection with an authenticated doctor
    conn = 
      conn
      |> AuthBypass.sign_in(@mock_doctor)
      |> init_test_session(%{})
    
    # Return the authenticated connection
    {:ok, conn: conn}
  end
  
  describe "doctor flow" do
    test "list_appointments shows appointments for the doctor", %{conn: conn} do
      # Mock the appointments API to return our mock appointment
      Mox.stub(Clinicpro.MockAsh.AppointmentsMock, :read, fn _, _, _ -> 
        {:ok, [@mock_appointment]} 
      end)
      
      # Start the workflow
      conn = post(conn, ~p"/doctor/start-workflow")
      
      # Verify we're redirected to the appointments list
      assert redirected_to(conn) == ~p"/doctor/appointments"
      
      # Follow the redirect
      conn = get(conn, ~p"/doctor/appointments")
      
      # Verify the page contains our appointment
      assert html_response(conn, 200) =~ "Appointments"
      assert html_response(conn, 200) =~ "Jane Doe"
      assert html_response(conn, 200) =~ "2025-07-25"
    end
    
    test "access_appointment shows appointment details", %{conn: conn} do
      # Mock the appointments API to return our mock appointment
      Mox.stub(Clinicpro.MockAsh.AppointmentsMock, :get, fn _, _, _ -> 
        {:ok, @mock_appointment} 
      end)
      
      # Start the workflow and set the current step
      conn = 
        conn
        |> post(~p"/doctor/start-workflow")
        |> put_session(:workflow_state, %{
          workflow_type: :doctor_flow,
          current_step: :access_appointment,
          appointment_id: "appt-456",
          started_at: DateTime.utc_now()
        })
      
      # Access the appointment
      conn = get(conn, ~p"/doctor/appointment/appt-456")
      
      # Verify the page contains appointment details
      assert html_response(conn, 200) =~ "Appointment Details"
      assert html_response(conn, 200) =~ "Jane Doe"
      assert html_response(conn, 200) =~ "2025-07-25"
    end
    
    test "fill_medical_details shows medical details form", %{conn: conn} do
      # Mock the appointments API to return our mock appointment
      Mox.stub(Clinicpro.MockAsh.AppointmentsMock, :get, fn _, _, _ -> 
        {:ok, @mock_appointment} 
      end)
      
      # Start the workflow and set the current step
      conn = 
        conn
        |> post(~p"/doctor/start-workflow")
        |> put_session(:workflow_state, %{
          workflow_type: :doctor_flow,
          current_step: :fill_medical_details,
          appointment_id: "appt-456",
          appointment_data: @mock_appointment,
          started_at: DateTime.utc_now()
        })
      
      # Access the medical details form
      conn = get(conn, ~p"/doctor/medical-details/appt-456")
      
      # Verify the page contains the medical details form
      assert html_response(conn, 200) =~ "Medical Details"
      assert html_response(conn, 200) =~ "Height"
      assert html_response(conn, 200) =~ "Weight"
      assert html_response(conn, 200) =~ "Blood Pressure"
    end
    
    test "record_diagnosis shows diagnosis form", %{conn: conn} do
      # Mock the appointments API to return our mock appointment
      Mox.stub(Clinicpro.MockAsh.AppointmentsMock, :get, fn _, _, _ -> 
        {:ok, @mock_appointment} 
      end)
      
      # Start the workflow and set the current step
      conn = 
        conn
        |> post(~p"/doctor/start-workflow")
        |> put_session(:workflow_state, %{
          workflow_type: :doctor_flow,
          current_step: :record_diagnosis,
          appointment_id: "appt-456",
          appointment_data: @mock_appointment,
          medical_details: %{
            "height" => "170",
            "weight" => "70",
            "blood_pressure" => "120/80",
            "temperature" => "36.6",
            "notes" => "Patient appears healthy"
          },
          started_at: DateTime.utc_now()
        })
      
      # Access the diagnosis form
      conn = get(conn, ~p"/doctor/diagnosis/appt-456")
      
      # Verify the page contains the diagnosis form
      assert html_response(conn, 200) =~ "Diagnosis"
      assert html_response(conn, 200) =~ "Treatment"
      assert html_response(conn, 200) =~ "Prescription"
    end
    
    test "complete_appointment shows completion page", %{conn: conn} do
      # Mock the appointments API to return our mock appointment
      Mox.stub(Clinicpro.MockAsh.AppointmentsMock, :get, fn _, _, _ -> 
        {:ok, @mock_appointment} 
      end)
      
      # Start the workflow and set the current step
      conn = 
        conn
        |> post(~p"/doctor/start-workflow")
        |> put_session(:workflow_state, %{
          workflow_type: :doctor_flow,
          current_step: :complete_appointment,
          appointment_id: "appt-456",
          appointment_data: @mock_appointment,
          medical_details: %{
            "height" => "170",
            "weight" => "70",
            "blood_pressure" => "120/80",
            "temperature" => "36.6",
            "notes" => "Patient appears healthy"
          },
          diagnosis: %{
            "diagnosis" => "Common cold",
            "treatment" => "Rest and fluids",
            "prescription" => "Paracetamol as needed"
          },
          started_at: DateTime.utc_now()
        })
      
      # Access the completion page
      conn = get(conn, ~p"/doctor/complete/appt-456")
      
      # Verify the page contains the completion information
      assert html_response(conn, 200) =~ "Appointment Completed"
      assert html_response(conn, 200) =~ "Jane Doe"
      assert html_response(conn, 200) =~ "Common cold"
    end
  end
end
