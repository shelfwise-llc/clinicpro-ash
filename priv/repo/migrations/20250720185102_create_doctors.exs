defmodule Clinicpro.Repo.Migrations.CreateDoctors do
  use Ecto.Migration

  def change do
    create table(:doctors) do
      add :name, :string
      add :specialty, :string
      add :email, :string
      add :phone, :string
      add :status, :string
      add :active, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:doctors, [:email])
  end
end
