defmodule Clinicpro.MockAuth do
  @moduledoc """
  Mock authentication module for testing.

  This module provides mock implementations of authentication-related functions
  to allow controller tests to run without requiring real authentication.
  """

  @doc """
  Mock function to simulate a signed-in user.
  Returns a mock user with the given attributes.
  """
  def sign_in(conn, attrs \\ %{}) do
    user = build_mock_user(attrs)

    Plug.Conn.assign(conn, :current_user, user)
  end

  @doc """
  Mock function to simulate a signed-out user.
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

  @doc """
  Build a mock user with the given attributes.
  """
  def build_mock_user(attrs \\ %{}) do
    default_attrs = %{
      id: Ecto.UUID.generate(),
      email: "test@example.com",
      first_name: "Test",
      last_name: "User",
      is_active: true
    }

    Map.merge(default_attrs, attrs)
  end

  @doc """
  Build a mock doctor user.
  """
  def build_mock_doctor(attrs \\ %{}) do
    doctor_attrs = %{
      email: "doctor@example.com",
      first_name: "Doctor",
      last_name: "Smith",
      roles: [%{name: "Doctor"}]
    }

    build_mock_user(Map.merge(doctor_attrs, attrs))
  end

  @doc """
  Build a mock admin user.
  """
  def build_mock_admin(attrs \\ %{}) do
    admin_attrs = %{
      email: "admin@example.com",
      first_name: "Admin",
      last_name: "User",
      roles: [%{name: "Clinic Admin"}]
    }

    build_mock_user(Map.merge(admin_attrs, attrs))
  end

  @doc """
  Build a mock patient user.
  """
  def build_mock_patient(attrs \\ %{}) do
    patient_attrs = %{
      email: "patient@example.com",
      first_name: "Patient",
      last_name: "Jones",
      roles: [%{name: "Patient"}]
    }

    build_mock_user(Map.merge(patient_attrs, attrs))
  end
end
