defmodule Clinicpro.MockAsh.ClinicsBehaviour do
  @moduledoc """
  Behaviour definition for mocking Clinics functionality in tests.
  """

  @callback get_clinic(any()) :: {:ok, map()} | {:error, any()}
  @callback update_clinic(any(), map()) :: {:ok, map()} | {:error, any()}
  @callback create_clinic(map()) :: {:ok, map()} | {:error, any()}
end
