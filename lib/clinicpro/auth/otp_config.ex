defmodule Clinicpro.Auth.OTPConfig do
  @moduledoc """
  Schema for storing clinic-specific OTP delivery configurations.
  This follows the same multi-tenant pattern as the M-Pesa configuration.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Clinicpro.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "otp_configs" do
    # Clinic identifier (string instead of association)
    field :clinic_identifier, :string

    # SMS Configuration
    field :sms_provider, :string
    field :sms_api_key, :string
    field :sms_sender_id, :string
    field :sms_enabled, :boolean, default: true

    # Email Configuration
    field :email_provider, :string
    field :email_api_key, :string
    field :email_from_address, :string
    field :email_enabled, :boolean, default: true

    # General Configuration
    field :preferred_method, :string, default: "sms" # "sms", "email", or "both"
    field :otp_expiry_minutes, :integer, default: 5

    # Rate limiting
    field :max_attempts_per_hour, :integer, default: 5
    field :lockout_minutes, :integer, default: 30

    timestamps()
  end

  def changeset(otp_config, attrs) do
    otp_config
    |> cast(attrs, [
      :clinic_identifier,
      :sms_provider,
      :sms_api_key,
      :sms_sender_id,
      :sms_enabled,
      :email_provider,
      :email_api_key,
      :email_from_address,
      :email_enabled,
      :preferred_method,
      :otp_expiry_minutes,
      :max_attempts_per_hour,
      :lockout_minutes
    ])
    |> validate_required([:clinic_identifier])
    |> validate_inclusion(:preferred_method, ["sms", "email", "both"])
    |> validate_number(:otp_expiry_minutes, greater_than: 0, less_than_or_equal_to: 60)
    |> validate_number(:max_attempts_per_hour, greater_than: 0, less_than_or_equal_to: 20)
    |> validate_number(:lockout_minutes, greater_than: 0, less_than_or_equal_to: 1440)
    |> unique_constraint(:clinic_identifier)
  end

  @doc """
  Gets the OTP configuration for a specific clinic.
  Creates a default configuration if one doesn't exist.
  """
  def get_config_for_clinic(clinic_identifier) do
    case Repo.get_by(__MODULE__, clinic_identifier: clinic_identifier) do
      nil ->
        # Create default configuration
        create_default_config(clinic_identifier)

      config ->
        {:ok, config}
    end
  end

  @doc """
  Creates a default OTP configuration for a clinic.
  """
  def create_default_config(clinic_identifier) do
    %__MODULE__{}
    |> changeset(%{
      clinic_identifier: clinic_identifier,
      sms_provider: "AfricasTalking",
      sms_sender_id: "ClinicPro",
      sms_enabled: true,
      email_provider: "SendGrid",
      email_enabled: true,
      preferred_method: "sms",
      otp_expiry_minutes: 5,
      max_attempts_per_hour: 5,
      lockout_minutes: 30
    })
    |> Repo.insert()
  end

  @doc """
  Updates the OTP configuration for a clinic.
  """
  def update_config(config, attrs) do
    config
    |> changeset(attrs)
    |> Repo.update()
  end
end
