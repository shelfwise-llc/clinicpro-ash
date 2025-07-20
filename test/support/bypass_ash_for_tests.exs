# This script sets up environment variables and mocks to bypass Ash resource compilation issues in tests
# It should be required at the beginning of test_helper.exs

# Define mock modules for Ash resources
defmodule Clinicpro.MockUser do
  defstruct [:id, :email, :role, :doctor, :patient]
end

defmodule Clinicpro.MockDoctor do
  defstruct [:id, :user_id, :clinic_id, :specialty, :first_name, :last_name, :email]
end

defmodule Clinicpro.MockPatient do
  defstruct [:id, :user_id, :first_name, :last_name, :date_of_birth]
end

defmodule Clinicpro.MockAppointment do
  defstruct [:id, :doctor_id, :patient_id, :date, :time, :status, :type]
end

defmodule Clinicpro.MockClinic do
  defstruct [:id, :name, :address, :phone]
end

defmodule Clinicpro.MockMedicalRecord do
  defstruct [:id, :patient_id, :doctor_id, :diagnosis, :treatment, :notes, :created_at, :updated_at]
end

# Define a mock authentication module for tests
defmodule Clinicpro.AuthBypass do
  @moduledoc """
  Bypass module for AshAuthentication in tests.
  
  This module provides simplified authentication functions for testing
  without requiring the full AshAuthentication system to be configured.
  """
  
  @doc """
  Sign in a user for testing purposes.
  """
  def sign_in(conn, user) do
    Plug.Conn.assign(conn, :current_user, user)
  end
  
  @doc """
  Sign out a user for testing purposes.
  """
  def sign_out(conn) do
    Plug.Conn.assign(conn, :current_user, nil)
  end
  
  @doc """
  Check if a user is signed in.
  """
  def signed_in?(conn) do
    !!conn.assigns[:current_user]
  end
  
  @doc """
  Get the current user from the connection.
  """
  def current_user(conn) do
    conn.assigns[:current_user]
  end
end

# Configure application to use mock modules
Application.put_env(:clinicpro, :auth_module, Clinicpro.AuthBypass)
