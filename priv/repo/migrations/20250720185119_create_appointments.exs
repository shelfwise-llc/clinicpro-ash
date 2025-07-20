defmodule Clinicpro.Repo.Migrations.CreateAppointments do
  use Ecto.Migration

  def change do
    create table(:appointments) do
      add :date, :date
      add :start_time, :time
      add :end_time, :time
      add :status, :string
      add :type, :string
      add :notes, :text
      add :doctor_id, references(:doctors, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:appointments, [:doctor_id])
    create index(:appointments, [:patient_id])
  end
end
