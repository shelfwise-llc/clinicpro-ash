defmodule Clinicpro.Repo.Migrations.CreateGuardianTokens do
  use Ecto.Migration

  def change do
    create table(:guardian_tokens, primary_key: false) do
      add :jti, :string, primary_key: true
      add :aud, :string, primary_key: true
      add :typ, :string
      add :iss, :string
      add :sub, :string
      add :exp, :bigint
      add :jwt, :text
      add :claims, :map
      add :clinic_id, :binary_id  # Added for multi-tenant support

      timestamps()
    end

    create index(:guardian_tokens, [:clinic_id])
    create index(:guardian_tokens, [:sub])
  end
end
