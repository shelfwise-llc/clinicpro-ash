defmodule Clinicpro.Repo.Migrations.CreateClinics do
  use Ecto.Migration

  def change do
    create table(:clinics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      timestamps(type: :utc_datetime)
    end
  end
end
