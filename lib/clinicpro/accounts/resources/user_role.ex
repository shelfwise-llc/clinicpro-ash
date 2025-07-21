defmodule Clinicpro.Accounts.UserRole do
  @moduledoc """
  UserRole resource for ClinicPro.
  
  This resource represents the many-to-many relationship between users and roles.
  It enables role-based access control in the system.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer]

  postgres do
    table "user_roles"
    repo Clinicpro.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :user_id, :uuid, allow_nil?: false
    attribute :role, :string, allow_nil?: false
    timestamps()
  end

  relationships do
    belongs_to :user, Clinicpro.Accounts.User
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
