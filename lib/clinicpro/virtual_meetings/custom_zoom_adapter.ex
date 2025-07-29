defmodule Clinicpro.VirtualMeetings.CustomZoomAdapter do
  @moduledoc """
  Custom Zoom adapter for virtual meetings.

  NOTE: Zoom integration is currently disabled. This adapter now delegates to SimpleAdapter.
  All Zoom API functionality has been disabled and this adapter now acts as a wrapper
  around SimpleAdapter to maintain interface compatibility.
  """

  @behaviour Clinicpro.VirtualMeetings.Adapter

  require Logger
  alias Clinicpro.VirtualMeetings.SimpleAdapter

  # Commented out as Zoom integration is disabled
  # @zoom_api_base_url "https://api.zoom.us/v2"

  @doc """
  Creates a new meeting for an appointment.

  NOTE: Zoom integration is disabled. This delegates to SimpleAdapter.

  ## Parameters

  * `appointment` - The appointment to create a meeting for
  * `opts` - Additional options for the meeting creation

  ## Returns

  * `{:ok, meeting_data}` - On success, returns meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def create_meeting(appointment, opts \\ []) do
    Logger.info(
      "Zoom integration disabled. Using SimpleAdapter for appointment #{appointment.id}"
    )

    SimpleAdapter.create_meeting(appointment, opts)
  end

  @doc """
  Updates an existing meeting for an appointment.

  NOTE: Zoom integration is disabled. This delegates to SimpleAdapter.

  ## Parameters

  * `appointment` - The appointment with the meeting to update
  * `opts` - Additional options for the meeting update

  ## Returns

  * `{:ok, meeting_data}` - On success, returns updated meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def update_meeting(appointment, opts \\ []) do
    Logger.info(
      "Zoom integration disabled. Using SimpleAdapter for appointment #{appointment.id}"
    )

    SimpleAdapter.update_meeting(appointment, opts)
  end

  @doc """
  Deletes an existing meeting for an appointment.

  NOTE: Zoom integration is disabled. This delegates to SimpleAdapter.

  ## Parameters

  * `appointment` - The appointment with the meeting to delete

  ## Returns

  * `:ok` - On success
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def delete_meeting(appointment) do
    Logger.info(
      "Zoom integration disabled. Using SimpleAdapter for appointment #{appointment.id}"
    )

    SimpleAdapter.delete_meeting(appointment)
  end

  @doc """
  DEPRECATED: This function is kept for backward compatibility but is no longer used.
  All calls are now routed through delete_meeting/1 which uses SimpleAdapter.

  Zoom integration is disabled. This delegates to SimpleAdapter.
  """
  def delete_meeting(appointment, _meeting_data, _opts \\ []) do
    Logger.warning("Deprecated delete_meeting/3 called. Using SimpleAdapter instead.")
    SimpleAdapter.delete_meeting(appointment)
  end

  # Private functions below are kept for reference but no longer used
  # They are commented out to prevent compilation warnings

  # # Gets an access token for the specified clinic
  # defp get_access_token(clinic_id) do
  #   # Implementation removed as Zoom integration is disabled
  #   {:error, :zoom_integration_disabled}
  # end

  # # Gets Zoom credentials for a specific clinic
  # defp get_zoom_credentials(clinic_id) do
  #   # Implementation removed as Zoom integration is disabled
  #   {:error, :zoom_integration_disabled}
  # end
  #
  # # Gets application-level Zoom credentials
  # defp get_app_zoom_credentials do
  #   # Implementation removed as Zoom integration is disabled
  #   {:error, :zoom_integration_disabled}
  # end

  # # Generates an OAuth2 access token for Zoom API
  # defp generate_access_token(credentials) do
  #   # Implementation removed as Zoom integration is disabled
  #   {:error, :zoom_integration_disabled}
  # end

  # # Creates a Zoom meeting with the given token and appointment details
  # defp create_zoom_meeting(token, appointment, _opts) do
  #   # Implementation removed as Zoom integration is disabled
  #   {:error, :zoom_integration_disabled}
  # end

  # # Updates a Zoom meeting with the given token and appointment details
  # defp update_zoom_meeting(token, appointment, meeting_data, _opts) do
  #   # Implementation removed as Zoom integration is disabled
  #   {:error, :zoom_integration_disabled}
  # end

  # # Deletes a Zoom meeting with the given token and meeting ID
  # defp delete_zoom_meeting(token, meeting_data, _opts) do
  #   # Implementation removed as Zoom integration is disabled
  #   {:error, :zoom_integration_disabled}
  # end

  # # Helper function to format appointment time for Zoom API
  # defp format_appointment_time(appointment) do
  #   # Implementation removed as Zoom integration is disabled
  #   ""
  # end

  # # Helper function to get doctor name
  # defp get_doctor_name(appointment) do
  #   # Implementation removed as Zoom integration is disabled
  #   ""
  # end
end
