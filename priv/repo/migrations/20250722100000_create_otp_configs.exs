defmodule Clinicpro.Repo.Migrations.CreateOtpConfigs do
  use Ecto.Migration

  def change do
    create table(:otp_configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :clinic_identifier, :string, null: false

      # SMS Configuration
      add :sms_provider, :string
      add :sms_api_key, :string
      add :sms_sender_id, :string
      add :sms_enabled, :boolean, default: true

      # Email Configuration
      add :email_provider, :string
      add :email_api_key, :string
      add :email_from_address, :string
      add :email_enabled, :boolean, default: true

      # General Configuration
      add :preferred_method, :string, default: "sms"
      add :otp_expiry_minutes, :integer, default: 5

      # Rate limiting
      add :max_attempts_per_hour, :integer, default: 5
      add :lockout_minutes, :integer, default: 30

      timestamps()
    end

    # Each clinic should have only one OTP configuration
    create unique_index(:otp_configs, [:clinic_identifier])
  end
end
