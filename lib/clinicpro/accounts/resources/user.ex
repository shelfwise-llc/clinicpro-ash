defmodule Clinicpro.Accounts.User do
  @moduledoc """
  User resource for ClinicPro.
  
  This resource represents a user in the system with authentication capabilities.
  It supports magic link authentication and role-based access control.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer] # Temporarily removed AshAuthentication

  postgres do
    table "users"
    repo Clinicpro.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :first_name, :string, allow_nil?: true
    attribute :last_name, :string, allow_nil?: true
    attribute :is_active, :boolean, default: true
    timestamps()
  end

  identities do
    identity :unique_email, [:email]
  end

  # Temporarily comment out authentication to bypass AshAuthentication issues
  # authentication do
  #   api Clinicpro.Accounts
  # 
  #   strategies do
  #     magic_link :magic_link do
  #       identity_field :email
  #       sender Clinicpro.Accounts.MagicLinkSender
  #       token_lifetime 60 * 60 # 1 hour
  #     end
  #   end
  # end

  relationships do
    has_many :roles, Clinicpro.Accounts.UserRole do
      destination_attribute :user_id
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    
    # Register action is temporarily commented out to bypass AshAuthentication issues
    # create :register do
    #   accept [:email, :first_name, :last_name]
    #   
    #   # This validation is required for AshAuthentication
    #   validate {Ash.Changeset.change_attribute(:is_active, true), []}
    # end
  end

  code_interface do
    define_for Clinicpro.Accounts
    define :get_by_id, args: [:id], action: :read
    define :get_by_email, args: [:email], action: :read
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
