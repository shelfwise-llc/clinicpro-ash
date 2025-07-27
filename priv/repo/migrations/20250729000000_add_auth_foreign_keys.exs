defmodule Clinicpro.Repo.Migrations.AddAuthForeignKeys do
  use Ecto.Migration

  def change do
    # Add foreign key constraint to auth_users.clinic_id
    alter table(:auth_users) do
      modify :clinic_id, references(:clinics, type: :binary_id, on_delete: :restrict), null: true
    end

    # Add foreign key constraint to auth_user_tokens.clinic_id
    alter table(:auth_user_tokens) do
      modify :clinic_id, references(:clinics, type: :binary_id, on_delete: :restrict), null: true
    end

    # Create index on auth_users.clinic_id for faster lookups
    create index(:auth_users, [:clinic_id])
    
    # Create index on auth_user_tokens.clinic_id for faster lookups
    create index(:auth_user_tokens, [:clinic_id])
  end
end
