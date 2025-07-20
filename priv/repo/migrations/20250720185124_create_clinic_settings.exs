defmodule Clinicpro.Repo.Migrations.CreateClinicSettings do
  use Ecto.Migration

  def change do
    create table(:clinic_settings) do
      add :key, :string
      add :value, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:clinic_settings, [:key])
  end
end
