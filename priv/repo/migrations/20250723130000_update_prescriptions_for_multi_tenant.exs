defmodule Clinicpro.Repo.Migrations.UpdatePrescriptionsForMultiTenant do
  use Ecto.Migration

  def change do
    # Create the prescriptions table if it doesn't exist
    # (since we're moving from ETS to Postgres)
    create_if_not_exists table(:prescriptions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :medication_name, :string, null: false
      add :dosage, :string, null: false
      add :frequency, :string, null: false
      add :duration, :string, null: false
      add :instructions, :string, default: ""
      add :created_at, :utc_datetime_usec, null: false

      add :appointment_id, references(:appointments, on_delete: :nilify_all)
      add :doctor_id, references(:doctors, on_delete: :nilify_all)
      add :patient_id, references(:patients, on_delete: :nilify_all)

      timestamps()
    end

    # Add new fields to the prescriptions table
    alter table(:prescriptions) do
      add :medication_code, :string
      add :medication_form, :string
      add :medication_strength, :string
      add :refills, :integer, default: 0
      add :is_controlled_substance, :boolean, default: false
      add :clinic_id, references(:clinics, on_delete: :nilify_all, type: :uuid)
    end

    # Add indexes for faster lookups
    create_if_not_exists index(:prescriptions, [:appointment_id])
    create_if_not_exists index(:prescriptions, [:doctor_id])
    create_if_not_exists index(:prescriptions, [:patient_id])
    create index(:prescriptions, [:clinic_id])
    create index(:prescriptions, [:medication_name])
  end
end
