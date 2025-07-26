defmodule Clinicpro.Appointments.Appointment do
  @moduledoc """
  Appointment resource for ClinicPro.

  This resource represents a scheduled _appointment between a patient and a doctor
  at a specific clinic.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer]

  postgres do
    table("appointments")
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
