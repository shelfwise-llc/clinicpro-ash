defmodule Clinicpro.MPesa.Config do
  @moduledoc """
  Manages M-Pesa configurations for multiple clinics.

  This module handles:
  1. Storing and retrieving clinic-specific M-Pesa credentials
  2. Encrypting sensitive data in the database
  3. Falling back to environment variables when clinic-specific config is missing
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Clinicpro.Repo
  alias Clinicpro.AdminBypass.Doctor

  schema "mpesa_configs" do
    field :consumer_key, :string
    field :consumer_secret, :string
    field :passkey, :string
    field :shortcode, :string
    # May differ from STK shortcode
    field :c2b_shortcode, :string
    field :environment, :string, default: "sandbox"
    field :stk_callback_url, :string
    field :c2b_validation_url, :string
    field :c2b_confirmation_url, :string
    field :active, :boolean, default: true

    belongs_to :clinic, Doctor, foreign_key: :clinic_id

    timestamps()
  end

  @doc """
  Creates a changeset for M-Pesa configuration.
  Validates required fields and formats.
  """
  def changeset(config, attrs) do
    config
    |> cast(attrs, [
      :consumer_key,
      :consumer_secret,
      :passkey,
      :shortcode,
      :c2b_shortcode,
      :environment,
      :stk_callback_url,
      :c2b_validation_url,
      :c2b_confirmation_url,
      :active,
      :clinic_id
    ])
    |> validate_required([
      :consumer_key,
      :consumer_secret,
      :passkey,
      :shortcode,
      :environment,
      :clinic_id
    ])
    |> validate_inclusion(:environment, ["sandbox", "production"])
    |> foreign_key_constraint(:clinic_id)
    |> maybe_encrypt_sensitive_fields()
  end

  @doc """
  Gets the M-Pesa configuration for a specific clinic.
  Falls back to environment variables if no clinic-specific config exists.
  """
  def get_for_clinic(clinic_id) do
    case Repo.get_by(__MODULE__, clinic_id: clinic_id, active: true) do
      nil -> get_from_env()
      config -> {:ok, decrypt_config(config)}
    end
  end

  @doc """
  Creates or updates M-Pesa configuration for a clinic.
  Encrypts sensitive fields before storing.
  """
  def upsert_config(clinic_id, attrs) do
    # Check if config exists for this clinic
    config =
      case Repo.get_by(__MODULE__, clinic_id: clinic_id) do
        nil -> %__MODULE__{clinic_id: clinic_id}
        existing -> existing
      end

    # Update or insert
    config
    |> changeset(Map.put(attrs, "clinic_id", clinic_id))
    |> Repo.insert_or_update()
  end

  @doc """
  Returns the default callback URLs based on the application's URL.
  """
  def default_callback_urls do
    base_url = System.get_env("APP_URL") || "https://clinicpro.example.com"

    %{
      stk_callback_url: "#{base_url}/api/mpesa/stk/callback",
      c2b_validation_url: "#{base_url}/api/mpesa/c2b/validation",
      c2b_confirmation_url: "#{base_url}/api/mpesa/c2b/confirmation"
    }
  end

  # Private functions

  # Get config from environment variables
  defp get_from_env do
    # Check if required env vars are set
    case System.get_env("MPESA_CONSUMER_KEY") do
      nil ->
        {:error, :config_not_found}

      _ ->
        {:ok,
         %{
           consumer_key: System.get_env("MPESA_CONSUMER_KEY"),
           consumer_secret: System.get_env("MPESA_CONSUMER_SECRET"),
           passkey: System.get_env("MPESA_PASSKEY"),
           shortcode: System.get_env("MPESA_SHORTCODE"),
           c2b_shortcode: System.get_env("MPESA_C2B_SHORTCODE"),
           environment: System.get_env("MPESA_ENVIRONMENT") || "sandbox",
           stk_callback_url: System.get_env("MPESA_STK_CALLBACK_URL"),
           c2b_validation_url: System.get_env("MPESA_C2B_VALIDATION_URL"),
           c2b_confirmation_url: System.get_env("MPESA_C2B_CONFIRMATION_URL"),
           active: true
         }}
    end
  end

  # Encrypt sensitive fields before saving to database
  defp maybe_encrypt_sensitive_fields(changeset) do
    if changeset.valid? do
      sensitive_fields = [:consumer_key, :consumer_secret, :passkey]

      Enum.reduce(sensitive_fields, changeset, fn field, acc ->
        case get_change(acc, field) do
          nil -> acc
          value -> put_change(acc, field, encrypt_value(value))
        end
      end)
    else
      changeset
    end
  end

  # Encrypt a value using Phoenix's secret_key_base
  defp encrypt_value(value) do
    # In a real app, use a proper encryption library
    # This is a simple placeholder that simulates encryption
    # by prepending "encrypted:" to the value
    "encrypted:" <> value
  end

  # Decrypt a config struct
  defp decrypt_config(config) do
    # In a production app, use a proper decryption library
    sensitive_fields = [:consumer_key, :consumer_secret, :passkey]

    decrypted =
      Enum.reduce(sensitive_fields, config, fn field, acc ->
        encrypted_value = Map.get(acc, field)
        decrypted_value = decrypt_value(encrypted_value)
        Map.put(acc, field, decrypted_value)
      end)

    decrypted
  end

  # Decrypt a value
  defp decrypt_value(nil), do: nil
  defp decrypt_value("encrypted:" <> value), do: value
  defp decrypt_value(value), do: value
end
