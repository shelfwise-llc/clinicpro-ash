defmodule Clinicpro.Accounts.Token do
  @moduledoc """
  Token resource for authentication.
  
  This resource is used by AshAuthentication to store authentication tokens.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer, AshAuthentication.TokenResource]

  postgres do
    table "tokens"
    repo Clinicpro.Repo
  end

  token do
    api Clinicpro.Accounts
  end

  attributes do
    uuid_primary_key :id
    attribute :type, :atom, allow_nil?: false
    attribute :token, :string, allow_nil?: false
    attribute :expires_at, :utc_datetime, allow_nil?: true
    timestamps()
  end

  relationships do
    belongs_to :user, Clinicpro.Accounts.User do
      allow_nil? false
    end
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
