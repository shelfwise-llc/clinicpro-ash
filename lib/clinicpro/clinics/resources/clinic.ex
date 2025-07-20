defmodule Clinicpro.Clinics.Clinic do
  @moduledoc """
  Clinic resource for ClinicPro.

  This resource represents a clinic in the system and is the core of the multi-tenancy model.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer]

  postgres do
    table "clinics"
    repo Clinicpro.Repo
  end

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if always()
    end

    policy action_type(:destroy) do
      authorize_if always()
    end
  end
end
