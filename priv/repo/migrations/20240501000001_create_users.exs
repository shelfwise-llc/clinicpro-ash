defmodule Clinicpro.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :confirmed_at, :naive_datetime
      add :role, :string, null: false, default: "user"
      add :clinic_id, references(:clinics, type: :binary_id, on_delete: :restrict)

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:clinic_id])
  end
end
