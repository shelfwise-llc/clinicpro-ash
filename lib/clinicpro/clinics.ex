defmodule Clinicpro.Clinics do
  @moduledoc """
  Clinics context for ClinicPro.

  This context handles clinic management and multi-tenancy.
  It follows Domain-Driven Design principles with clear separation of concerns.
  """
  use Ash.Api

  resources do
    registry(Clinicpro.Clinics.Registry)
  end
end
