defmodule Clinicpro.VirtualMeetings.CustomZoomAdapter do
  @moduledoc """
  Custom Zoom adapter for virtual meetings.

  This adapter creates, updates, and deletes Zoom meetings using the Zoom API.
  It requires Zoom API credentials to be configured in the application environment.
  It supports multi-tenant configuration where each clinic has its own Zoom credentials.
  """

  @behaviour Clinicpro.VirtualMeetings.Adapter

  require Logger
  alias Clinicpro.AdminBypass.Appointment
  # # alias Clinicpro.Repo
  alias HTTPoison
  alias Jason
  alias OAuth2.Client

  @zoom_api_base_url "https://api.zoom.us/v2"

  @doc """
  Creates a new Zoom meeting for an _appointment.

  ## Parameters

  * `_appointment` - The _appointment to create a meeting for
  * `_opts` - Additional options for the meeting creation

  ## Returns

  * `{:ok, meeting_data}` - On success, returns meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def create_meeting(_appointment, _opts \\ []) do
    # Get the _clinic_id from the _appointment
    _clinic_id = _appointment._clinic_id

    # Get access token for the clinic
    case get_access_token(_clinic_id) do
      {:ok, token} ->
        # Create meeting with the token
        create_zoom_meeting(token, _appointment, _opts)

      {:error, reason} ->
        Logger.error("Failed to get Zoom access token: #{inspect(reason)}")
        {:error, :auth_failed}
    end
  end

  @doc """
  Updates an existing Zoom meeting for an _appointment.

  ## Parameters

  * `_appointment` - The _appointment to update the meeting for
  * `meeting_data` - The existing meeting data
  * `_opts` - Additional options for the meeting update

  ## Returns

  * `{:ok, meeting_data}` - On success, returns updated meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def update_meeting(_appointment, meeting_data, _opts \\ []) do
    # Get the _clinic_id from the _appointment
    _clinic_id = _appointment._clinic_id

    # Get access token for the clinic
    case get_access_token(_clinic_id) do
      {:ok, token} ->
        # Update meeting with the token
        update_zoom_meeting(token, _appointment, meeting_data, _opts)

      {:error, reason} ->
        Logger.error("Failed to get Zoom access token: #{inspect(reason)}")
        {:error, :auth_failed}
    end
  end

  @doc """
  Deletes an existing Zoom meeting.

  ## Parameters

  * `_appointment` - The _appointment to delete the meeting for
  * `meeting_data` - The existing meeting data
  * `_opts` - Additional options for the meeting deletion

  ## Returns

  * `{:ok, result}` - On success, returns the result
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def delete_meeting(_appointment, meeting_data, _opts \\ []) do
    # Get the _clinic_id from the _appointment
    _clinic_id = _appointment._clinic_id

    # Get access token for the clinic
    case get_access_token(_clinic_id) do
      {:ok, token} ->
        # Delete meeting with the token
        delete_zoom_meeting(token, meeting_data, _opts)

      {:error, reason} ->
        Logger.error("Failed to get Zoom access token: #{inspect(reason)}")
        {:error, :auth_failed}
    end
  end

  # Private functions

  # Gets an access token for the specified clinic
  defp get_access_token(_clinic_id) do
    # First try to get clinic-specific credentials
    case get_zoom_credentials(_clinic_id) do
      {:ok, credentials} ->
        generate_access_token(credentials)

      {:error, _reason} ->
        # Fall back to application-level credentials
        case get_app_zoom_credentials() do
          {:ok, credentials} ->
            generate_access_token(credentials)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  # Gets Zoom credentials for a specific clinic
  defp get_zoom_credentials(_clinic_id) do
    # This would typically query the database for clinic-specific credentials
    # For now, we'll just return a mock result
    {:ok,
     %{
       client_id: "clinic_#{_clinic_id}_client_id",
       client_secret: "clinic_#{_clinic_id}_client_secret",
       account_id: "clinic_#{_clinic_id}_account_id"
     }}
  end

  # Gets application-level Zoom credentials
  defp get_app_zoom_credentials do
    client_id = System.get_env("ZOOM_CLIENT_ID")
    client_secret = System.get_env("ZOOM_CLIENT_SECRET")
    account_id = System.get_env("ZOOM_ACCOUNT_ID")

    if client_id && client_secret && account_id do
      {:ok,
       %{
         client_id: client_id,
         client_secret: client_secret,
         account_id: account_id
       }}
    else
      {:error, :missing_credentials}
    end
  end

  # Generates an OAuth2 access token for Zoom API
  defp generate_access_token(credentials) do
    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.ClientCredentials,
        client_id: credentials.client_id,
        client_secret: credentials.client_secret,
        site: "https://zoom.us",
        token_url: "/oauth/token",
        params: %{"account_id" => credentials.account_id}
      )

    case OAuth2.Client.get_token(client) do
      {:ok, %{token: %{access_token: access_token}}} ->
        {:ok, access_token}

      {:error, %{body: body}} ->
        Logger.error("Failed to get Zoom access token: #{inspect(body)}")
        {:error, :token_generation_failed}

      error ->
        Logger.error("Unexpected error getting Zoom token: #{inspect(error)}")
        {:error, :unexpected_error}
    end
  end

  # Creates a Zoom meeting with the given token and _appointment details
  defp create_zoom_meeting(token, _appointment, _opts) do
    url = "#{@zoom_api_base_url}/users/me/meetings"

    # Format the _appointment date and time for Zoom
    start_time = format_appointment_time(_appointment)

    # Prepare the request body
    body =
      Jason.encode!(%{
        topic: "Appointment with Dr. #{get_doctor_name(_appointment)}",
        # Scheduled meeting
        type: 2,
        start_time: start_time,
        duration: _appointment.duration,
        timezone: "UTC",
        settings: %{
          host_video: true,
          participant_video: true,
          join_before_host: true,
          mute_upon_entry: true,
          waiting_room: false,
          auto_recording: "none"
        }
      })

    # Make the API request
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: status, body: response_body}} when status in 200..299 ->
        case Jason.decode(response_body) do
          {:ok, data} ->
            # Extract relevant meeting data
            meeting_data = %{
              meeting_id: data["id"],
              join_url: data["join_url"],
              password: data["password"],
              host_email: data["host_email"],
              provider: "zoom"
            }

            {:ok, meeting_data}

          {:error, _unused} ->
            Logger.error("Failed to parse Zoom API response: #{inspect(response_body)}")
            {:error, :invalid_response}
        end

      {:ok, %{status_code: status, body: response_body}} ->
        Logger.error("Zoom API error (#{status}): #{inspect(response_body)}")
        {:error, :api_error}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end

  # Updates a Zoom meeting with the given token and _appointment details
  defp update_zoom_meeting(token, _appointment, meeting_data, _opts) do
    meeting_id = meeting_data[:meeting_id]

    if is_nil(meeting_id) do
      {:error, :missing_meeting_id}
    else
      url = "#{@zoom_api_base_url}/meetings/#{meeting_id}"

      # Format the _appointment date and time for Zoom
      start_time = format_appointment_time(_appointment)

      # Prepare the request body
      body =
        Jason.encode!(%{
          topic: "Appointment with Dr. #{get_doctor_name(_appointment)}",
          # Scheduled meeting
          type: 2,
          start_time: start_time,
          duration: _appointment.duration,
          timezone: "UTC",
          settings: %{
            host_video: true,
            participant_video: true,
            join_before_host: true,
            mute_upon_entry: true,
            waiting_room: false,
            auto_recording: "none"
          }
        })

      # Make the API request
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.patch(url, body, headers) do
        {:ok, %{status_code: status}} when status in 200..299 ->
          # Meeting updated successfully, return the original meeting data
          # with any updates from the _appointment
          updated_meeting_data =
            Map.merge(meeting_data, %{
              provider: "zoom"
            })

          {:ok, updated_meeting_data}

        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Zoom API error (#{status}): #{inspect(response_body)}")
          {:error, :api_error}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP request failed: #{inspect(reason)}")
          {:error, :request_failed}
      end
    end
  end

  # Deletes a Zoom meeting with the given token and meeting ID
  defp delete_zoom_meeting(token, meeting_data, _opts) do
    meeting_id = meeting_data[:meeting_id]

    if is_nil(meeting_id) do
      {:error, :missing_meeting_id}
    else
      url = "#{@zoom_api_base_url}/meetings/#{meeting_id}"

      # Make the API request
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.delete(url, headers) do
        {:ok, %{status_code: status}} when status in 200..299 ->
          # Meeting deleted successfully
          {:ok, %{deleted: true}}

        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Zoom API error (#{status}): #{inspect(response_body)}")
          {:error, :api_error}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP request failed: #{inspect(reason)}")
          {:error, :request_failed}
      end
    end
  end

  # Helper function to format _appointment time for Zoom API
  defp format_appointment_time(_appointment) do
    naive_datetime =
      NaiveDateTime.new!(
        _appointment.appointment_date,
        _appointment.appointment_time
      )

    # Convert to ISO8601 format
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  # Helper function to get doctor name
  defp get_doctor_name(_appointment) do
    # In a real implementation, this would look up the doctor's name
    # For now, we'll just return a placeholder
    "Doctor (ID: #{_appointment.doctor_id})"
  end
end
