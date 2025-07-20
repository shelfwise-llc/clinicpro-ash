defmodule Clinicpro.Mocks do
  @moduledoc """
  Mock definitions for testing.
  
  This module defines Mox mocks for Ash resources to allow controller tests
  to run without requiring real Ash resource compilation.
  """
  
  # Define mocks for Ash APIs
  Mox.defmock(Clinicpro.MockAsh.AppointmentsMock, for: Clinicpro.MockAsh.AppointmentsBehaviour)
  Mox.defmock(Clinicpro.MockAsh.PatientsMock, for: Clinicpro.MockAsh.PatientsBehaviour)
  Mox.defmock(Clinicpro.MockAsh.ClinicsMock, for: Clinicpro.MockAsh.ClinicsBehaviour)
end

defmodule Clinicpro.MockAsh.AppointmentsBehaviour do
  @moduledoc """
  Behaviour for mocking Appointments API.
  """
  @callback get_appointment(String.t()) :: map()
  @callback list_appointments(String.t()) :: [map()]
  @callback create_appointment(map()) :: {:ok, map()} | {:error, any()}
  @callback update_appointment(String.t(), map()) :: {:ok, map()} | {:error, any()}
end

defmodule Clinicpro.MockAsh.PatientsBehaviour do
  @moduledoc """
  Behaviour for mocking Patients API.
  """
  @callback get_patient(String.t()) :: map()
  @callback list_patients() :: [map()]
  @callback create_patient(map()) :: {:ok, map()} | {:error, any()}
  @callback update_patient(String.t(), map()) :: {:ok, map()} | {:error, any()}
end

defmodule Clinicpro.MockAsh.ClinicsBehaviour do
  @moduledoc """
  Behaviour for mocking Clinics API.
  """
  @callback get_clinic(String.t()) :: map()
  @callback list_clinics() :: [map()]
  @callback create_clinic(map()) :: {:ok, map()} | {:error, any()}
  @callback update_clinic(String.t(), map()) :: {:ok, map()} | {:error, any()}
end
