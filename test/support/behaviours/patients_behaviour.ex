defmodule Clinicpro.MockAsh.PatientsBehaviour do
  @moduledoc """
  Behaviour definition for mocking Patients functionality in tests.
  """

  @callback get_patient(any()) :: {:ok, map()} | {:error, any()}
  @callback update_patient(any(), map()) :: {:ok, map()} | {:error, any()}
  @callback create_patient(map()) :: {:ok, map()} | {:error, any()}
end
