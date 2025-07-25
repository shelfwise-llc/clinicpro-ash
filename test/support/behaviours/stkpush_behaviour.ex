defmodule Clinicpro.MPesa.STKPushBehaviour do
  @moduledoc """
  Behaviour definition for mocking M-Pesa STK Push functionality in tests.
  """
  
  @callback initiate(map()) :: {:ok, map()} | {:error, any()}
  @callback query_status(binary(), map()) :: {:ok, map()} | {:error, any()}
end
