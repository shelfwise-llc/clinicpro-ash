defmodule Clinicpro.Repo.Migrations.CreateAdminBypassTables do
  use Ecto.Migration

  def change do
    # Create doctors table for admin bypass
    create_if_not_exists table(:admin_bypass_doctors) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :specialty, :string
      add :bio, :text
      add :active, :boolean, default: true
      add :years_of_experience, :integer
      add :consultation_fee, :decimal, precision: 10, scale: 2

      timestamps()
    end

    create_if_not_exists unique_index(:admin_bypass_doctors, [:email])

    # Create patients table for admin bypass
    create_if_not_exists table(:admin_bypass_patients) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :date_of_birth, :date
      add :gender, :string
      add :medical_history, :text
      add :active, :boolean, default: true

      timestamps()
    end

    create_if_not_exists unique_index(:admin_bypass_patients, [:email])

    # Create appointments table for admin bypass
    create_if_not_exists table(:admin_bypass_appointments) do
      add :doctor_id, references(:admin_bypass_doctors, on_delete: :delete_all), null: false
      add :patient_id, references(:admin_bypass_patients, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :status, :string, default: "scheduled"
      add :notes, :text
      add :reason, :string
      add :diagnosis, :text
      add :prescription, :text

      timestamps()
    end

    create_if_not_exists index(:admin_bypass_appointments, [:doctor_id])
    create_if_not_exists index(:admin_bypass_appointments, [:patient_id])
    create_if_not_exists index(:admin_bypass_appointments, [:date])
    create_if_not_exists index(:admin_bypass_appointments, [:status])
  end
end
