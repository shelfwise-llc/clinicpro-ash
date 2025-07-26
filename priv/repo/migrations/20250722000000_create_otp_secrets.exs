defmodule Clinicpro.Repo.Migrations.CreateOtpSecrets do
  use Ecto.Migration

  def change do
    create table(:otp_secrets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :secret, :string, null: false
      add :active, :boolean, default: true, null: false
      add :expires_at, :utc_datetime

      # Patient reference
      add :patient_id, references(:patients, on_delete: :delete_all), null: false

      # Clinic identifier (string instead of reference since there's no clinics table)
      add :clinic_identifier, :string, null: false

      timestamps()
    end

    create index(:otp_secrets, [:patient_id])
    create index(:otp_secrets, [:clinic_identifier])
    create index(:otp_secrets, [:active])
  end
end
