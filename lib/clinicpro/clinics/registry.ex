defmodule Clinicpro.Clinics.Registry do
  @moduledoc """
  Registry for Clinics resources.

  This module registers all resources in the Clinics bounded context.
  """
  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry(Clinicpro.Clinics.Clinic)
    entry(Clinicpro.Clinics.ClinicStaff)
  end
end
