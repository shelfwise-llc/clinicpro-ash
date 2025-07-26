defmodule Clinicpro.AshConfig do
  @moduledoc """
  Global Ash configuration for the ClinicPro application.
  This module configures Ash resources, APIs, and registries.
  """
  # In newer versions of Ash, the module is Ash.Registry
  use Ash.Registry

  @doc """
  Configure all Ash APIs for the application.
  """
  def apis do
    [
      Clinicpro.Accounts,
      Clinicpro.Clinics,
      Clinicpro.Appointments,
      Clinicpro.Payments,
      Clinicpro.Notifications,
      Clinicpro.Invoicing
    ]
  end

  @doc """
  Configure global settings for all resources.
  """
  def resources do
    []
  end

  @doc """
  Configure add-on extensions.
  """
  def extensions do
    [
      # Core extensions
      Ash.Policy.Authorizer,

      # Data persistence
      AshPostgres.DataLayer,

      # API extensions
      AshJsonApi.DataLayer,

      # Authentication
      AshAuthentication
    ]
  end
end
