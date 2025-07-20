defmodule Clinicpro.AccountsAPIBehaviour do
  @moduledoc """
  Behaviour module for Accounts API.
  
  This module defines the behaviour that mock implementations must follow.
  """
  
  @callback get_user(String.t()) :: {:ok, map()} | {:error, any()}
  @callback get_user_by_email(String.t()) :: {:ok, map()} | {:error, any()}
  @callback create_user(map()) :: {:ok, map()} | {:error, any()}
  @callback authenticate_by_magic_link(String.t()) :: {:ok, map()} | {:error, any()}
  @callback send_magic_link(String.t()) :: {:ok, any()} | {:error, any()}
end

defmodule Clinicpro.AppointmentsAPIBehaviour do
  @moduledoc """
  Behaviour module for Appointments API.
  
  This module defines the behaviour that mock implementations must follow.
  """
  
  @callback get_appointment(String.t()) :: {:ok, map()} | {:error, any()}
  @callback list_appointments(map()) :: {:ok, list(map())} | {:error, any()}
  @callback create_appointment(map()) :: {:ok, map()} | {:error, any()}
  @callback update_appointment(String.t(), map()) :: {:ok, map()} | {:error, any()}
  @callback delete_appointment(String.t()) :: {:ok, map()} | {:error, any()}
end
