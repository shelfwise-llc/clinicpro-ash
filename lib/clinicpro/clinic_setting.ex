defmodule Clinicpro.ClinicSetting do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  # # alias Clinicpro.Repo
  alias __MODULE__

  @default_settings %{
    "clinic_name" => "ClinicPro Medical Center",
    "clinic_address" => "123 Health Street, Medical District",
    "clinic_phone" => "(555) 123-4567",
    "clinic_email" => "info@clinicpro.com",
    "clinic_website" => "https://clinicpro.com",
    "business_hours_mon" => "9:00-17:00",
    "business_hours_tue" => "9:00-17:00",
    "business_hours_wed" => "9:00-17:00",
    "business_hours_thu" => "9:00-17:00",
    "business_hours_fri" => "9:00-17:00",
    "business_hours_sat" => "10:00-14:00",
    "business_hours_sun" => "Closed",
    "appointment_duration" => "30",
    "email_notifications" => "true",
    "sms_notifications" => "true",
    "appointment_reminders" => "24"
  }

  schema "clinic_settings" do
    field :value, :string
    field :key, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a clinic setting.
  """
  def changeset(clinic_setting, attrs) do
    clinic_setting
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint(:key)
  end

  @doc """
  Gets a setting by key.
  Returns the default value if the setting doesn't exist.
  """
  def get(key) do
    case Repo.get_by(ClinicSetting, key: key) do
      nil -> Map.get(@default_settings, key)
      setting -> setting.value
    end
  end

  @doc """
  Gets all settings as a map.
  """
  def get_all do
    settings =
      ClinicSetting
      |> Repo.all()
      |> Enum.reduce(%{}, fn setting, acc ->
        Map.put(acc, setting.key, setting.value)
      end)

    # Merge with defaults for any missing settings
    Map.merge(@default_settings, settings)
  end

  @doc """
  Sets a setting value by key.
  Creates the setting if it doesn't exist.
  """
  def set(key, value) do
    case Repo.get_by(ClinicSetting, key: key) do
      nil ->
        %ClinicSetting{}
        |> changeset(%{key: key, value: value})
        |> Repo.insert()

      setting ->
        setting
        |> changeset(%{value: value})
        |> Repo.update()
    end
  end

  @doc """
  Sets multiple settings at once.
  """
  def set_many(settings_map) when is_map(settings_map) do
    Enum.each(settings_map, fn {key, value} ->
      set(key, value)
    end)
  end

  @doc """
  Ensures all default settings exist in the database.
  """
  def initialize_defaults do
    Enum.each(@default_settings, fn {key, value} ->
      case Repo.get_by(ClinicSetting, key: key) do
        nil ->
          %ClinicSetting{}
          |> changeset(%{key: key, value: value})
          |> Repo.insert()

        _unused ->
          :ok
      end
    end)
  end
end
