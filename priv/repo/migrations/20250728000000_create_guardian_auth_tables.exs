defmodule Clinicpro.Repo.Migrations.CreateGuardianAuthTables do
  use Ecto.Migration

  def up do
    # Execute a safe check if the table exists
    query = """
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public'
        AND table_name = 'guardian_tokens'
      );
    """

    table_exists =
      case Ecto.Adapters.SQL.query(Clinicpro.Repo, query, []) do
        {:ok, %{rows: [[true]]}} -> true
        _ -> false
      end

    unless table_exists do
      # Create guardian_tokens table for GuardianDB
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
    # No down migration needed - we don't want to drop the table
    # if it was created by another migration
  end
end
