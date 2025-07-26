defmodule ClinicproWeb.ControllerTestBypass do
  @moduledoc """
  Helper module for controller tests that bypasses AshAuthentication.

  This module provides helper functions for setting up controller tests
  with our mock modules instead of real Ash resources.
  """

  import Phoenix.ConnTest
  import Plug.Conn

  # Define structs locally to avoid compilation order issues
  defmodule MockUser do
    defstruct [:id, :email, :role, :doctor, :patient, :admin]
  end

  defmodule MockDoctor do
    defstruct [:id, :first_name, :last_name, :specialty, :clinic_id]
  end

  defmodule MockPatient do
    defstruct [:id, :first_name, :last_name, :date_of_birth]
  end

  defmodule MockAppointment do
    defstruct [:id, :patient_name, :date, :time, :reason, :status, :clinic_id, :doctor_id, :patient_id, :type, :medical_details, :diagnosis]
  end

  alias Clinicpro.Mocks.Accounts

  @endpoint ClinicproWeb.Endpoint

  @doc """
  Sets up a connection with a mock user and workflow state.
  """
  def setup_conn_with_user(conn, user, workflow_type, current_step, opts \\ %{}) do
    conn
    |> init_test_session(%{})
    |> Accounts.sign_in(user)
    |> setup_workflow_state(workflow_type, current_step, opts)
  end

  @doc """
  Sets up workflow state in the session.
  """
  def setup_workflow_state(conn, workflow_type, current_step, opts \\ %{}) do
    workflow_state =
      Map.merge(
        %{
          workflow_type: workflow_type,
          current_step: current_step,
          started_at: DateTime.utc_now()
        },
        opts
      )

    conn
    |> put_session(:workflow_state, workflow_state)
  end

  @doc """
  Creates a mock doctor user.
  """
  def mock_doctor(attrs \\ %{}) do
    doctor_id = Map.get(attrs, :doctor_id, "doctor-123")

    %MockUser{
      id: Map.get(attrs, :id, "user-123"),
      email: Map.get(attrs, :email, "doctor@example.com"),
      role: :doctor,
      doctor: %MockDoctor{
        id: doctor_id,
        first_name: Map.get(attrs, :first_name, "John"),
        last_name: Map.get(attrs, :last_name, "Smith"),
        specialty: Map.get(attrs, :specialty, "General Medicine"),
        clinic_id: Map.get(attrs, :clinic_id, "clinic-123")
      }
    }
  end

  @doc """
  Creates a mock patient user.
  """
  def mock_patient(attrs \\ %{}) do
    patient_id = Map.get(attrs, :patient_id, "patient-456")

    %MockUser{
      id: Map.get(attrs, :id, "user-456"),
      email: Map.get(attrs, :email, "patient@example.com"),
      role: :patient,
      patient: %MockPatient{
        id: patient_id,
        first_name: Map.get(attrs, :first_name, "Jane"),
        last_name: Map.get(attrs, :last_name, "Doe"),
        date_of_birth: Map.get(attrs, :date_of_birth, "1990-01-01")
      }
    }
  end

  @doc """
  Creates a mock appointment.
  """
  def mock_appointment(attrs \\ %{}) do
    %MockAppointment{
      id: Map.get(attrs, :id, "appt-456"),
      doctor_id: Map.get(attrs, :doctor_id, "doctor-123"),
      patient_id: Map.get(attrs, :patient_id, "patient-456"),
      date: Map.get(attrs, :date, "2025-07-25"),
      time: Map.get(attrs, :time, "10:00 AM"),
      type: Map.get(attrs, :type, "Consultation"),
      status: Map.get(attrs, :status, "scheduled")
    }
  end
end
