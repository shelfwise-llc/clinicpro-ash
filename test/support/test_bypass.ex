defmodule Clinicpro.TestBypass do
  @moduledoc """
  Test bypass module for ClinicPro.
  
  This module provides mock implementations and bypass functions for Ash resources
  and AshAuthentication to enable controller tests to run without requiring the full
  Ash framework and authentication system to compile.
  
  It addresses the "key :type not found in: nil" error in the magic link transformer
  by providing mock implementations of the authentication functions.
  
  This allows controller tests to run without requiring the full Ash framework to compile.
  """
  
  @doc """
  Bypasses Ash authentication for tests.
  
  This function sets up mocks for Ash authentication functions to allow
  controller tests to run without requiring the full Ash authentication
  system to compile correctly.
  
  It specifically addresses the "key :type not found in: nil" error in the magic link transformer
  by providing mock implementations of the authentication functions that don't rely on
  AshAuthentication token configuration.
  """
  def bypass_ash_authentication do
    # Define mock modules for authentication
    defmodule Clinicpro.AuthBypass do
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
          {:ok, %{id: Ecto.UUID.generate(), email: email, role: :patient}}
        else
          {:error, :invalid_token}
        end
      end
    end
  end
  
  @doc """
  Sets up the test environment to bypass Ash resources and authentication.
  This should be called in test_helper.exs before running tests.
  """
  def setup do
    # Set up mocks for Ash APIs
    Application.put_env(:clinicpro, :ash_apis, %{
      accounts: Clinicpro.MockAccounts,
      appointments: Clinicpro.MockAppointments,
      clinics: Clinicpro.MockClinics,
      medical_records: Clinicpro.MockMedicalRecords
    })
    
    # Set up authentication bypass
    Application.put_env(:clinicpro, :auth_module, Clinicpro.AuthBypass)
  end
  
  @doc """
  Creates mock modules for Ash APIs.
  This should be called in test_helper.exs before running tests.
  """
  def create_mock_modules do
    # Define mock modules for Ash APIs
    defmodule Clinicpro.MockAccounts do
      def read(_resource, _query, _opts), do: {:ok, []}
      def get(_resource, _id, _opts), do: {:ok, nil}
      def create(_resource, _params, _opts), do: {:ok, %{id: Ecto.UUID.generate()}}
      def update(_resource, _record, _params, _opts), do: {:ok, %{}}
      def destroy(_resource, _record, _opts), do: {:ok, %{}}
    end
    
    defmodule Clinicpro.MockAppointments do
      def read(_resource, _query, _opts) do
        appointments = [
          %{
            id: "appt-123",
            doctor_id: "doctor-123",
            patient_id: "patient-456",
            date: "2025-07-25",
            time: "10:00 AM",
            type: "Consultation",
            status: "scheduled",
            patient: %{
              id: "patient-456",
              first_name: "Jane",
              last_name: "Doe"
            }
          }
        ]
        {:ok, appointments}
      end
      
      def get(_resource, _id, _opts) do
        appointment = %{
          id: "appt-123",
          doctor_id: "doctor-123",
          patient_id: "patient-456",
          date: "2025-07-25",
          time: "10:00 AM",
          type: "Consultation",
          status: "scheduled",
          patient: %{
            id: "patient-456",
            first_name: "Jane",
            last_name: "Doe"
          }
        }
        {:ok, appointment}
      end
      
      def create(_resource, _params, _opts), do: {:ok, %{id: Ecto.UUID.generate()}}
      def update(_resource, _record, _params, _opts), do: {:ok, %{}}
      def destroy(_resource, _record, _opts), do: {:ok, %{}}
    end
    
    defmodule Clinicpro.MockClinics do
      def read(_resource, _query, _opts) do
        clinics = [
          %{
            id: "clinic-123",
            name: "Main Clinic",
            address: "123 Main St",
            city: "Anytown",
            state: "CA",
            zip: "12345",
            phone: "555-123-4567"
          }
        ]
        {:ok, clinics}
      end
      
      def get(_resource, _id, _opts) do
        clinic = %{
          id: "clinic-123",
          name: "Main Clinic",
          address: "123 Main St",
          city: "Anytown",
          state: "CA",
          zip: "12345",
          phone: "555-123-4567"
        }
        {:ok, clinic}
      end
    end
    
    defmodule Clinicpro.MockMedicalRecords do
      def read(_resource, _query, _opts), do: {:ok, []}
      def get(_resource, _id, _opts), do: {:ok, nil}
      def create(_resource, _params, _opts), do: {:ok, %{id: Ecto.UUID.generate()}}
      def update(_resource, _record, _params, _opts), do: {:ok, %{}}
    end
  end
end
