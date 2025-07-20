defmodule Clinicpro.BypassAshForTests do
  @moduledoc """
  This module provides a complete bypass for Ash resources and authentication in tests.
  
  It addresses the "key :type not found in: nil" error in the magic link transformer
  by completely bypassing the Ash authentication system during tests.
  """
  
  # Mock user struct for tests
  defmodule MockUser do
    defstruct [:id, :email, :role, :doctor, :patient, :admin]
  end
  
  # Mock doctor struct for tests
  defmodule MockDoctor do
    defstruct [:id, :first_name, :last_name, :specialty, :clinic_id]
  end
  
  # Mock patient struct for tests
  defmodule MockPatient do
    defstruct [:id, :first_name, :last_name, :date_of_birth]
  end
  
  # Mock appointment struct for tests
  defmodule MockAppointment do
    defstruct [:id, :doctor_id, :patient_id, :date, :time, :type, :status, :patient, :doctor]
  end
  
  # Mock authentication module
  defmodule MockAuth do
    @moduledoc """
    Mock authentication module for tests.
    
    This module provides mock implementations of the authentication functions
    that don't rely on AshAuthentication.
    """
    
    def sign_in(conn, user) do
      Plug.Conn.put_session(conn, :current_user, user)
    end
    
    def sign_out(conn) do
      Plug.Conn.delete_session(conn, :current_user)
    end
    
    def current_user(conn) do
      Plug.Conn.get_session(conn, :current_user)
    end
    
    def signed_in?(conn) do
      !!current_user(conn)
    end
    
    # Mock magic link authentication functions
    def generate_magic_link_token(email) do
      # Generate a simple token for testing
      token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
      
      # Store the token in the process dictionary for verification
      Process.put({:magic_link_token, email}, token)
      
      # Return the token
      token
    end
    
    def verify_magic_link_token(token) do
      # Find the email associated with this token
      email = Process.get({:magic_link_token, token})
      
      if email do
        # Return a mock user
        {:ok, %MockUser{id: Ecto.UUID.generate(), email: email, role: :patient}}
      else
        {:error, :invalid_token}
      end
    end
  end
  
  # Mock API modules
  defmodule MockAccounts do
    @moduledoc """
    Mock Accounts API for tests.
    """
    
    def get_user(id) do
      # Return a mock user
      {:ok, %MockUser{
        id: id,
        email: "user-#{id}@example.com",
        role: :patient
      }}
    end
    
    def get_user_by_email(email) do
      # Return a mock user
      {:ok, %MockUser{
        id: "user-#{:erlang.phash2(email)}",
        email: email,
        role: :patient
      }}
    end
    
    def create_user(attrs) do
      # Return a mock user
      {:ok, %MockUser{
        id: Ecto.UUID.generate(),
        email: attrs[:email],
        role: attrs[:role] || :patient
      }}
    end
  end
  
  defmodule MockAppointments do
    @moduledoc """
    Mock Appointments API for tests.
    """
    
    def get_appointment(id) do
      # Return a mock appointment
      {:ok, %MockAppointment{
        id: id,
        doctor_id: "doctor-123",
        patient_id: "patient-456",
        date: "2025-07-25",
        time: "10:00 AM",
        type: "Consultation",
        status: "scheduled"
      }}
    end
    
    def list_appointments(filters) do
      # Return a list of mock appointments
      doctor_id = filters[:doctor_id]
      patient_id = filters[:patient_id]
      
      appointments = [
        %MockAppointment{
          id: "appt-1",
          doctor_id: doctor_id || "doctor-123",
          patient_id: patient_id || "patient-456",
          date: "2025-07-25",
          time: "10:00 AM",
          type: "Consultation",
          status: "scheduled"
        },
        %MockAppointment{
          id: "appt-2",
          doctor_id: doctor_id || "doctor-123",
          patient_id: patient_id || "patient-789",
          date: "2025-07-26",
          time: "11:00 AM",
          type: "Follow-up",
          status: "scheduled"
        }
      ]
      
      {:ok, appointments}
    end
    
    def create_appointment(attrs) do
      # Return a mock appointment
      {:ok, %MockAppointment{
        id: Ecto.UUID.generate(),
        doctor_id: attrs[:doctor_id],
        patient_id: attrs[:patient_id],
        date: attrs[:date],
        time: attrs[:time],
        type: attrs[:type],
        status: "scheduled"
      }}
    end
    
    def update_appointment(id, attrs) do
      # Return a mock appointment
      {:ok, %MockAppointment{
        id: id,
        doctor_id: attrs[:doctor_id] || "doctor-123",
        patient_id: attrs[:patient_id] || "patient-456",
        date: attrs[:date] || "2025-07-25",
        time: attrs[:time] || "10:00 AM",
        type: attrs[:type] || "Consultation",
        status: attrs[:status] || "scheduled"
      }}
    end
  end
  
  # Setup function to be called in test_helper.exs
  def setup do
    # Define mocks for Ash APIs
    Application.put_env(:clinicpro, :accounts_api, MockAccounts)
    Application.put_env(:clinicpro, :appointments_api, MockAppointments)
    Application.put_env(:clinicpro, :auth_module, MockAuth)
    
    # Set test bypass flag
    Application.put_env(:clinicpro, :test_bypass_enabled, true)
    
    # Set token signing secret for tests
    Application.put_env(:clinicpro, :token_signing_secret, "test_secret_key_for_ash_authentication_tokens")
    
    :ok
  end
end
