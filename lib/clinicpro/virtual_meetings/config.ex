defmodule Clinicpro.VirtualMeetings.Config do
  @moduledoc """
  Configuration module for virtual meetings.

  This module provides functions for configuring and managing virtual meeting adapters.
  It supports multi-tenant configuration, allowing different clinics to use different
  meeting providers or configurations.
  """

  require Logger
  alias Clinicpro.Repo
  alias Clinicpro.Clinics.Clinic

  @doc """
  Gets the virtual meeting adapter configuration for a specific clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to get the configuration for

  ## Returns

  * `{:ok, config}` - On success, returns the configuration map
  * `{:error, reason}` - On failure, returns an error reason
  """
  def get_clinic_config(clinic_id) do
    case Repo.get(Clinic, clinic_id) do
      nil ->
        {:error, :clinic_not_found}

      clinic ->
        # Extract clinic-specific configuration from the clinic record
        # This assumes that clinics have virtual_meeting_config field
        config =
          case clinic.virtual_meeting_config do
            nil -> get_app_config()
            config when is_map(config) -> Map.merge(get_app_config(), config)
            _unused -> get_app_config()
          end

        {:ok, config}
    end
  end

  @doc """
  Gets the application-wide virtual meeting configuration.

  ## Returns

  * Map containing the virtual meeting configuration
  """
  def get_app_config do
    %{
      adapter: get_adapter(),
      base_url: get_base_url(),
      google_api_credentials: get_google_api_credentials(),
      zoom_api_credentials: get_zoom_api_credentials(),
      google_calendar_id: get_google_calendar_id()
    }
  end

  @doc """
  Gets the configured virtual meeting adapter module.

  ## Returns

  * The adapter module to use for virtual meetings
  """
  def get_adapter do
    Application.get_env(:clinicpro, :virtual_meetings, [])
    |> Keyword.get(:adapter, Clinicpro.VirtualMeetings.SimpleAdapter)
  end

  @doc """
  Gets the configured base URL for virtual meetings.

  ## Returns

  * The base URL to use for virtual meetings
  """
  def get_base_url do
    Application.get_env(:clinicpro, :virtual_meetings, [])
    |> Keyword.get(:base_url, "https://meet.clinicpro.com")
  end

  @doc """
  Gets the configured Google API credentials for virtual meetings.

  ## Returns

  * The Google API credentials map or nil if not configured
  """
  def get_google_api_credentials do
    Application.get_env(:clinicpro, :google_api_credentials)
  end

  @doc """
  Gets the configured Zoom API credentials for virtual meetings.

  ## Returns

  * The Zoom API credentials map or nil if not configured
  """
  def get_zoom_api_credentials do
    Application.get_env(:clinicpro, :zoom_api_credentials)
  end

  @doc """
  Gets the configured Google Calendar ID for virtual meetings.

  ## Returns

  * The Google Calendar ID to use for virtual meetings
  """
  def get_google_calendar_id do
    Application.get_env(:clinicpro, :google_calendar_id, "primary")
  end

  @doc """
  Sets the virtual meeting adapter module.

  ## Parameters

  * `adapter` - The adapter module to use
  """
  def set_adapter(adapter) do
    current_config = Application.get_env(:clinicpro, :virtual_meetings, [])
    updated_config = Keyword.put(current_config, :adapter, adapter)
    Application.put_env(:clinicpro, :virtual_meetings, updated_config)
  end

  @doc """
  Sets the virtual meeting base URL.

  ## Parameters

  * `base_url` - The base URL to use
  """
  def set_base_url(base_url) do
    current_config = Application.get_env(:clinicpro, :virtual_meetings, [])
    updated_config = Keyword.put(current_config, :base_url, base_url)
    Application.put_env(:clinicpro, :virtual_meetings, updated_config)
  end

  @doc """
  Sets the Google API credentials for virtual meetings.

  ## Parameters

  * `credentials` - The credentials to use
  """
  def set_google_api_credentials(credentials) do
    Application.put_env(:clinicpro, :google_api_credentials, credentials)
  end

  @doc """
  Sets the Zoom API credentials for virtual meetings.

  ## Parameters

  * `credentials` - The credentials to use
  """
  def set_zoom_api_credentials(credentials) do
    Application.put_env(:clinicpro, :zoom_api_credentials, credentials)
  end

  @doc """
  Sets the Google Calendar ID for virtual meetings.

  ## Parameters

  * `calendar_id` - The calendar ID to use
  """
  def set_google_calendar_id(calendar_id) do
    Application.put_env(:clinicpro, :google_calendar_id, calendar_id)
  end

  @doc """
  Sets the virtual meeting configuration for a specific clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to set the configuration for
  * `config` - The configuration map to set

  ## Returns

  * `{:ok, clinic}` - On success, returns the updated clinic
  * `{:error, reason}` - On failure, returns an error reason
  """
  def set_clinic_config(clinic_id, config) do
    case Repo.get(Clinic, clinic_id) do
      nil ->
        {:error, :clinic_not_found}

      clinic ->
        # Update the clinic's virtual meeting configuration
        changeset = Clinic.changeset(clinic, %{virtual_meeting_config: config})
        Repo.update(changeset)
    end
  end

  @doc """
  Sets the virtual meeting adapter for a specific clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to set the adapter for
  * `adapter` - The adapter module to use

  ## Returns

  * `{:ok, clinic}` - On success, returns the updated clinic
  * `{:error, reason}` - On failure, returns an error reason
  """
  def set_clinic_adapter(clinic_id, adapter) do
    case get_clinic_config(clinic_id) do
      {:ok, config} ->
        updated_config = Map.put(config, :adapter, adapter)
        set_clinic_config(clinic_id, updated_config)

      error ->
        error
    end
  end

  @doc """
  Sets the virtual meeting base URL for a specific clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to set the base URL for
  * `base_url` - The base URL to use

  ## Returns

  * `{:ok, clinic}` - On success, returns the updated clinic
  * `{:error, reason}` - On failure, returns an error reason
  """
  def set_clinic_base_url(clinic_id, base_url) do
    case get_clinic_config(clinic_id) do
      {:ok, config} ->
        updated_config = Map.put(config, :base_url, base_url)
        set_clinic_config(clinic_id, updated_config)

      error ->
        error
    end
  end

  @doc """
  Sets the Google API credentials for a specific clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to set the credentials for
  * `credentials` - The credentials to use

  ## Returns

  * `{:ok, clinic}` - On success, returns the updated clinic
  * `{:error, reason}` - On failure, returns an error reason
  """
  def set_clinic_google_api_credentials(clinic_id, credentials) do
    case get_clinic_config(clinic_id) do
      {:ok, config} ->
        updated_config = Map.put(config, :google_api_credentials, credentials)
        set_clinic_config(clinic_id, updated_config)

      error ->
        error
    end
  end

  @doc """
  Sets the Zoom API credentials for a specific clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to set the credentials for
  * `credentials` - The credentials to use

  ## Returns

  * `{:ok, clinic}` - On success, returns the updated clinic
  * `{:error, reason}` - On failure, returns an error reason
  """
  def set_clinic_zoom_api_credentials(clinic_id, credentials) do
    case get_clinic_config(clinic_id) do
      {:ok, config} ->
        updated_config = Map.put(config, :zoom_api_credentials, credentials)
        set_clinic_config(clinic_id, updated_config)

      error ->
        error
    end
  end
end
