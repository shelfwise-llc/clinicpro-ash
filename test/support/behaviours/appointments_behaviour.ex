defmodule Clinicpro.MockAsh.AppointmentsBehaviour do
  @moduledoc """
  Behaviour definition for mocking Appointments functionality in tests.
  """
  
  @callback get_appointment(any()) :: {:ok, map()} | {:error, any()}
  @callback update_appointment(any(), map()) :: {:ok, map()} | {:error, any()}
  @callback create_new_appointment(map()) :: {:ok, map()} | {:error, any()}
end
