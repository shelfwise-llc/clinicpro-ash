defmodule Clinicpro.Patients.Patient do
  @moduledoc """
  Patient resource for ClinicPro.

  This resource represents a patient in the system with their basic information
  and relationships to medical records and appointments.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer]

  postgres do
    table "_patients"
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
