defmodule Clinicpro.Accounts.Registry do
  @moduledoc """
  Registry for Accounts resources.

  This module registers all resources in the Accounts context.
  """
  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry(Clinicpro.Accounts.User)
    entry(Clinicpro.Accounts.Role)
    entry(Clinicpro.Accounts.UserRole)
    entry(Clinicpro.Accounts.Token)
  end
end
