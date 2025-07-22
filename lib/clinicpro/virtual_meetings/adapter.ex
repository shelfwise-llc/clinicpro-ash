defmodule Clinicpro.VirtualMeetings.Adapter do
  @moduledoc """
  Behaviour module for virtual meeting adapters.

  This module defines the behaviour that all virtual meeting adapters must implement.
  It also provides helper functions for selecting and using adapters.
  """

  alias Clinicpro.VirtualMeetings.Config
  alias Clinicpro.VirtualMeetings.CustomZoomAdapter
  alias Clinicpro.VirtualMeetings.GoogleMeetAdapter
  alias Clinicpro.VirtualMeetings.SimpleAdapter

  @doc """
  Creates a new virtual meeting for an appointment.

  ## Parameters

  * `appointment` - The appointment for which to create a meeting
  * `opts` - Additional options for the meeting creation

  ## Returns

  * `{:ok, meeting_data}` - On success, returns meeting data with URL and details
  * `{:error, reason}` - On failure, returns an error reason
  """
  @callback create_meeting(appointment :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Updates an existing virtual meeting for an appointment.

  ## Parameters

  * `appointment` - The appointment with the meeting to update
  * `opts` - Additional options for the meeting update

  ## Returns

  * `{:ok, meeting_data}` - On success, returns updated meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @callback update_meeting(appointment :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Deletes an existing virtual meeting for an appointment.

  ## Parameters

  * `appointment` - The appointment with the meeting to delete

  ## Returns

  * `:ok` - On success
  * `{:error, reason}` - On failure, returns an error reason
  """
  @callback delete_meeting(appointment :: map()) :: :ok | {:error, term()}

  @doc """
  Gets the configured adapter module to use for virtual meetings.

  ## Parameters

  * `clinic_id` - Optional clinic ID to get clinic-specific adapter

  ## Returns

  * Adapter module to use for virtual meetings
  """
  defp get_adapter(clinic_id) do
    # If clinic_id is provided, try to get clinic-specific adapter
    if clinic_id do
      case Config.get_clinic_config(clinic_id) do
        {:ok, config} ->
          # Get adapter from clinic config or fall back to app config
          adapter_name = Map.get(config, :adapter)
          resolve_adapter(adapter_name)

        _ ->
          # Fall back to application-level adapter
          get_app_adapter()
      end
    else
      # No clinic_id provided, use application-level adapter
      get_app_adapter()
    end
  end

  @doc """
  Creates a new virtual meeting using the configured adapter.

  ## Parameters

  * `appointment` - The appointment for which to create a meeting
  * `opts` - Additional options for the meeting creation
  * `clinic_id` - Optional clinic ID to use clinic-specific adapter

  ## Returns

  * `{:ok, meeting_data}` - On success, returns meeting data with URL and details
  * `{:error, reason}` - On failure, returns an error reason
  """
  def create_meeting(appointment, opts \\ [], clinic_id \\ nil) do
    adapter = get_adapter(clinic_id)
    adapter.create_meeting(appointment, opts)
  end

  @doc """
  Updates an existing virtual meeting using the configured adapter.

  ## Parameters

  * `appointment` - The appointment with the meeting to update
  * `opts` - Additional options for the meeting update
  * `clinic_id` - Optional clinic ID to use clinic-specific adapter

  ## Returns

  * `{:ok, meeting_data}` - On success, returns updated meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  def update_meeting(appointment, opts \\ [], clinic_id \\ nil) do
    adapter = get_adapter(clinic_id)
    adapter.update_meeting(appointment, opts)
  end

  @doc """
  Deletes an existing virtual meeting using the configured adapter.

  ## Parameters

  * `appointment` - The appointment with the meeting to delete
  * `clinic_id` - Optional clinic ID to use clinic-specific adapter

  ## Returns

  * `:ok` - On success
  * `{:error, reason}` - On failure, returns an error reason
  """
  def delete_meeting(appointment, clinic_id \\ nil) do
    adapter = get_adapter(clinic_id)
    adapter.delete_meeting(appointment)
  end

  # Private helper functions for adapter resolution

  # Get the application-level adapter
  defp get_app_adapter do
    adapter_name = Config.get_adapter()
    resolve_adapter(adapter_name)
  end

  # Resolve adapter name to adapter module
  defp resolve_adapter(adapter_name) do
    case adapter_name do
      "google_meet" -> GoogleMeetAdapter
      "zoom" -> CustomZoomAdapter
      "simple" -> SimpleAdapter
      nil -> SimpleAdapter  # Default to SimpleAdapter if not configured
      _ -> SimpleAdapter    # Default to SimpleAdapter for unknown adapters
    end
  end
end
