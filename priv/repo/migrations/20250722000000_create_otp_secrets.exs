defmodule Clinicpro.Repo.Migrations.CreateOtpSecrets do
  use Ecto.Migration

  def change do
    create table(:otp_secrets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :secret, :string, null: false
      add :active, :boolean, default: true, null: false
      add :last_used_at, :utc_datetime
      add :expires_at, :utc_datetime

      # Multi-tenant fields
      add :patient_id, references(:patients, type: :binary_id, on_delete: :delete_all), null: false
      add :clinic_id, references(:clinics, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    # Indexes for faster lookups
    create index(:otp_secrets, [:patient_id])
    create index(:otp_secrets, [:clinic_id])
    create index(:otp_secrets, [:patient_id, :clinic_id, :active])
    create index(:otp_secrets, [:expires_at])
  end
end
