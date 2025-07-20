defmodule Clinicpro.Repo.Migrations.CreateAdmins do
  use Ecto.Migration

  def change do
    create table(:admins) do
      add :email, :string
      add :name, :string
      add :password_hash, :string
      add :role, :string
      add :active, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:admins, [:email])
  end
end
