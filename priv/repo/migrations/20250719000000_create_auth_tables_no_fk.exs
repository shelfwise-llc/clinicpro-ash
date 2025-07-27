defmodule Clinicpro.Repo.Migrations.CreateAuthTablesNoFk do
  use Ecto.Migration

  def up do
    # Helper function to check if a table exists
    table_exists = fn table_name ->
      query = """
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public'
          AND table_name = '#{table_name}'
        );
      """
      
      case Ecto.Adapters.SQL.query(Clinicpro.Repo, query, []) do
        {:ok, %{rows: [[true]]}} -> true
        _ -> false
      end
    end
    # Create auth_users table without foreign key constraints
    unless table_exists.(:auth_users) do
      create table(:auth_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :role, :string, default: "user"
      add :confirmed_at, :naive_datetime
      add :clinic_id, :binary_id, null: true  # No foreign key constraint

      timestamps()
      end

      create unique_index(:auth_users, [:email])
    end

    # Create auth_user_tokens table without foreign key constraints for clinic_id
    unless table_exists.(:auth_user_tokens) do
      create table(:auth_user_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :user_id, references(:auth_users, type: :binary_id, on_delete: :delete_all), null: false
      add :clinic_id, :binary_id, null: true  # No foreign key constraint

      timestamps(updated_at: false)
      end

      create index(:auth_user_tokens, [:user_id])
      create unique_index(:auth_user_tokens, [:context, :token])
    end

    # Create guardian_tokens table for GuardianDB
    unless table_exists.(:guardian_tokens) do
      create table(:guardian_tokens, primary_key: false) do
      add :jti, :string, primary_key: true
      add :aud, :string, primary_key: true
      add :typ, :string
      add :iss, :string
      add :sub, :string
      add :exp, :bigint
      add :jwt, :text
      add :claims, :map

      timestamps()
      end

      create index(:guardian_tokens, [:jti, :aud])
      create index(:guardian_tokens, [:sub])
    end
  end
  
  def down do
    # Not reversible since we're fixing migration conflicts
  end
end
