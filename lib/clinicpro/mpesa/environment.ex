defmodule Clinicpro.MPesa.Environment do
  @moduledoc """
  Environment-specific configuration for M-Pesa integration.

  This module provides functions to determine whether M-Pesa should be enabled
  or disabled based on the current environment and configuration.
  """

  @doc """
  Checks if M-Pesa integration is enabled for the current environment.

  Returns:
    * `true` - M-Pesa is enabled
    * `false` - M-Pesa is disabled
  """
  def enabled? do
    Application.get_env(:clinicpro, :mpesa_enabled, false)
  end

  @doc """
  Returns the appropriate M-Pesa implementation module based on the environment.

  Returns:
    * `Clinicpro.MPesa.Implementation` - When M-Pesa is enabled
    * `Clinicpro.MPesa.Disabled` - When M-Pesa is disabled
  """
  def implementation_module do
    if enabled?() do
      Clinicpro.MPesa.Implementation
    else
      Clinicpro.MPesa.Disabled
    end
  end
end
