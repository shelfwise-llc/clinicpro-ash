defmodule Clinicpro.Repo.Migrations.CreatePatients do
  use Ecto.Migration

  def change do
    create table(:patients) do
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :phone, :string
      add :date_of_birth, :date
      add :gender, :string
      add :address, :text
      add :medical_history, :text
      add :insurance_provider, :string
      add :insurance_number, :string
      add :status, :string
      add :active, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:patients, [:email])
  end
end
