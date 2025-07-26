defmodule Clinicpro.Accounts.Role do
  @moduledoc """
  Role resource for ClinicPro.

  This resource represents a role in the system for role-based access control.
  Roles include Super Admin, Clinic Admin, Doctor, Nurse, and Patient.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer]

  postgres do
    table("roles")
    repo(Clinicpro.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    timestamps()
  end

  actions do
    defaults([:create, :read, :update, :destroy])
  end

  policies do
    policy action_type(:read) do
      authorize_if(always())
    end

    policy action_type(:create) do
      authorize_if(always())
    end

    policy action_type(:update) do
      authorize_if(always())
    end

    policy action_type(:destroy) do
      authorize_if(always())
    end
  end
end
