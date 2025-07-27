defmodule Clinicpro.Repo.Migrations.CreateUserTokens do
  use Ecto.Migration

  def change do
    create table(:user_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :clinic_id, references(:clinics, type: :binary_id, on_delete: :restrict)

      timestamps(updated_at: false)
    end

    create index(:user_tokens, [:user_id])
    create index(:user_tokens, [:clinic_id])
    create unique_index(:user_tokens, [:context, :token])
  end
end
