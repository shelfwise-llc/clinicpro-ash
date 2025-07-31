defmodule Clinicpro.Repo.Migrations.AddMultiTenantSupport do
  use Ecto.Migration

  def change do
    # Add clinic_id to existing tables for multi-tenant support
    alter table(:patients) do
      add :clinic_id, :string
    end

    create index(:patients, [:clinic_id])

    alter table(:doctors) do
      add :clinic_id, :string
    end

    create index(:doctors, [:clinic_id])

    alter table(:admins) do
      add :clinic_id, :string
    end

    create index(:admins, [:clinic_id])

    # Create magic_links table for passwordless authentication
    create table(:magic_links) do
      add :token, :string, null: false
      add :email, :string, null: false
      add :clinic_id, :string, null: false
      add :user_type, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :used_at, :utc_datetime
      timestamps()
    end

    create unique_index(:magic_links, [:token])
    create index(:magic_links, [:email, :clinic_id])
    create index(:magic_links, [:expires_at])
  end
end
