defmodule ClinicproWeb.ControllerTestHelper do
  @moduledoc """
  Helper functions for controller tests.
  Provides mock data and functions to simulate Ash resources without requiring compilation.
  """
  
  import Phoenix.ConnTest
  import Plug.Conn
  
  @endpoint ClinicproWeb.Endpoint
  
  @doc """
  Sets up a test connection with session and optional workflow state.
  Also allows setting up a mock authenticated user.
  """
  def setup_conn(workflow_type \\ nil, current_step \\ nil, user_type \\ nil) do
    conn = Phoenix.ConnTest.build_conn()
           |> Plug.Test.init_test_session(%{})
           |> maybe_sign_in_user(user_type)
    
    if workflow_type do
      workflow_state = %{
        workflow_type: workflow_type,
        current_step: current_step || get_first_step(workflow_type),
        started_at: DateTime.utc_now()
      }
      
      conn
      |> put_session(:workflow_state, workflow_state)
    else
      conn
    end
  end
  
  @doc """
  Signs in a mock user based on the user type.
  """
  def maybe_sign_in_user(conn, nil), do: conn
  def maybe_sign_in_user(conn, :doctor), do: Clinicpro.AuthBypass.sign_in(conn, build_mock_doctor())
  def maybe_sign_in_user(conn, :admin), do: Clinicpro.AuthBypass.sign_in(conn, build_mock_admin())
  def maybe_sign_in_user(conn, :patient), do: Clinicpro.AuthBypass.sign_in(conn, build_mock_patient())
  def maybe_sign_in_user(conn, user_attrs) when is_map(user_attrs), do: Clinicpro.AuthBypass.sign_in(conn, user_attrs)
  
  @doc """
  Build a mock doctor user for testing.
  """
  def build_mock_doctor do
    %{
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
  end
  
  @doc """
  Build a mock admin user for testing.
  """
  def build_mock_admin do
    %{
      id: "user-456",
      email: "admin@example.com",
      role: :admin
    }
  end
  
  @doc """
  Build a mock patient user for testing.
  """
  def build_mock_patient do
    %{
      id: "user-789",
      email: "patient@example.com",
      role: :patient,
      patient: %{
        id: "patient-123",
        first_name: "Jane",
        last_name: "Doe",
        date_of_birth: ~D[1990-01-01]
      }
    }
  end
  
  @doc """
  Gets the first step for a workflow type.
  """
  def get_first_step(workflow_type) do
    case workflow_type do
      :patient_flow -> :receive_link
      :doctor_flow -> :list_appointments
      :guest_booking -> :initiate
      :search -> :search
      _ -> :start
    end
  end
  
  @doc """
  Mock appointment data for tests.
  """
  def mock_appointment(attrs \\ %{}) do
    Map.merge(%{
      id: Ecto.UUID.generate(),
      scheduled_at: DateTime.utc_now() |> DateTime.add(3600),
      duration_minutes: 30,
      reason: "Regular checkup",
      notes: "Patient requested morning appointment",
      status: :scheduled,
      patient_id: Ecto.UUID.generate(),
      doctor_id: Ecto.UUID.generate(),
      clinic_id: Ecto.UUID.generate(),
      created_at: DateTime.utc_now() |> DateTime.add(-86400),
      updated_at: DateTime.utc_now()
    }, attrs)
  end
  
  @doc """
  Mock patient data for tests.
  """
  def mock_patient(attrs \\ %{}) do
    Map.merge(%{
      id: Ecto.UUID.generate(),
      first_name: "John",
      last_name: "Doe",
      date_of_birth: ~D[1980-01-01],
      gender: :male,
      phone: "+1234567890",
      email: "john.doe@example.com",
      address: "123 Main St",
      city: "Anytown",
      state: "CA",
      postal_code: "12345",
      user_id: Ecto.UUID.generate(),
      created_at: DateTime.utc_now() |> DateTime.add(-86400),
      updated_at: DateTime.utc_now()
    }, attrs)
  end
  
  @doc """
  Mock doctor data for tests.
  """
  def mock_doctor(attrs \\ %{}) do
    Map.merge(%{
      id: Ecto.UUID.generate(),
      first_name: "Jane",
      last_name: "Smith",
      specialization: "General Practice",
      license_number: "MD12345",
      bio: "Experienced doctor with 10+ years of practice",
      user_id: Ecto.UUID.generate(),
      clinic_id: Ecto.UUID.generate(),
      created_at: DateTime.utc_now() |> DateTime.add(-86400),
      updated_at: DateTime.utc_now()
    }, attrs)
  end
  
  @doc """
  Mock clinic data for tests.
  """
  def mock_clinic(attrs \\ %{}) do
    Map.merge(%{
      id: Ecto.UUID.generate(),
      name: "Main Street Clinic",
      address: "456 Main St",
      city: "Anytown",
      state: "CA",
      postal_code: "12345",
      phone: "+1987654321",
      email: "info@mainclinic.example.com",
      website: "https://mainclinic.example.com",
      created_at: DateTime.utc_now() |> DateTime.add(-86400),
      updated_at: DateTime.utc_now()
    }, attrs)
  end
  
  @doc """
  Mock medical record data for tests.
  """
  def mock_medical_record(attrs \\ %{}) do
    Map.merge(%{
      id: Ecto.UUID.generate(),
      diagnosis: "Common cold",
      treatment: "Rest and fluids",
      notes: "Patient should recover within a week",
      patient_id: Ecto.UUID.generate(),
      appointment_id: Ecto.UUID.generate(),
      created_by_id: Ecto.UUID.generate(),
      created_at: DateTime.utc_now() |> DateTime.add(-86400),
      updated_at: DateTime.utc_now()
    }, attrs)
  end
end
