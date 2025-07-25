defmodule Clinicpro.VirtualMeetings.ZoomAdapter do
  @moduledoc """
  Zoom adapter for virtual meetings.

  This adapter creates, updates, and deletes Zoom meetings using the Zoom API.
  It requires Zoom API credentials to be configured in the application environment.
  """

  @behaviour Clinicpro.VirtualMeetings.Adapter

  require Logger
  alias Clinicpro.AdminBypass.Appointment
  # # alias Clinicpro.Repo
  alias HTTPoison
  alias Jason

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
    with {:ok, _appointment} <- get_appointment_with_associations(_appointment),
         {:ok, token} <- get_access_token(_appointment._clinic_id),
         {:ok, meeting} <- create_zoom_meeting(token, _appointment, _opts) do

      # Extract meeting details from the created meeting
      meeting_data = %{
        url: meeting["join_url"],
        token: generate_token(),
        provider: "zoom",
        meeting_id: meeting["id"],
        created_at: DateTime.utc_now(),
        password: meeting["password"],
        host_email: meeting["host_email"],
        start_url: meeting["start_url"]
      }

      {:ok, meeting_data}
    else
      {:error, %{status_code: status, body: body}} ->
        Logger.error("Zoom API error: #{status} - #{inspect(body)}")
        {:error, "Failed to create Zoom meeting: #{status}"}

      {:error, reason} ->
        Logger.error("Failed to create Zoom meeting: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Updates an existing Zoom meeting.

  ## Parameters

  * `_appointment` - The _appointment with the meeting to update
  * `_opts` - Additional options for the meeting update

  ## Returns

  * `{:ok, meeting_data}` - On success, returns updated meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def update_meeting(_appointment, _opts \\ []) do
    with {:ok, _appointment} <- get_appointment_with_associations(_appointment),
         meeting_data <- extract_meeting_data(_appointment),
         {:ok, token} <- get_access_token(_appointment._clinic_id),
         {:ok, meeting} <- update_zoom_meeting(token, _appointment, meeting_data, _opts) do

      # Extract updated meeting details
      updated_meeting_data = %{
        url: meeting["join_url"],
        provider: "zoom",
        meeting_id: meeting["id"],
        updated_at: DateTime.utc_now(),
        password: meeting["password"],
        host_email: meeting["host_email"],
        start_url: meeting["start_url"]
      }

      {:ok, Map.merge(meeting_data, updated_meeting_data)}
    else
      {:error, %{status_code: status, body: body}} ->
        Logger.error("Zoom API error: #{status} - #{inspect(body)}")
        {:error, "Failed to update Zoom meeting: #{status}"}

      {:error, reason} ->
        Logger.error("Failed to update Zoom meeting: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Deletes an existing Zoom meeting.

  ## Parameters

  * `_appointment` - The _appointment with the meeting to delete
  * `_opts` - Additional options for the meeting deletion

  ## Returns

  * `:ok` - On success
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def delete_meeting(_appointment, _opts \\ []) do
    with {:ok, _appointment} <- get_appointment_with_associations(_appointment),
         meeting_data <- extract_meeting_data(_appointment),
         {:ok, token} <- get_access_token(_appointment._clinic_id),
         {:ok, _response} <- delete_zoom_meeting(token, meeting_data, _opts) do
      :ok
    else
      {:error, %{status_code: status, body: body}} ->
        Logger.error("Zoom API error: #{status} - #{inspect(body)}")
        {:error, "Failed to delete Zoom meeting: #{status}"}

      {:error, reason} ->
        Logger.error("Failed to delete Zoom meeting: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp get_appointment_with_associations(%Appointment{} = _appointment) do
    _appointment = Repo.preload(_appointment, [:patient, :doctor, :clinic])
    {:ok, _appointment}
  end

  defp get_appointment_with_associations(appointment_id) when is_integer(appointment_id) do
    case Appointment.get_appointment(appointment_id) do
      {:ok, _appointment} -> get_appointment_with_associations(_appointment)
      error -> error
    end
  end

  defp get_access_token(_clinic_id) do
    # First try to get clinic-specific credentials
    case get_zoom_credentials(_clinic_id) do
      {:ok, credentials} ->
        generate_access_token(credentials)

      {:error, :not_found} ->
        # Fall back to application-wide credentials
        case get_zoom_credentials() do
          {:ok, credentials} -> generate_access_token(credentials)
          error -> error
        end
    end
  end

  defp get_zoom_credentials(_clinic_id \\ nil) do
    cond do
      # Try to get clinic-specific credentials if _clinic_id is provided
      not is_nil(_clinic_id) ->
        case Clinicpro.VirtualMeetings.Config.get_clinic_config(_clinic_id) do
          {:ok, %{zoom_api_credentials: credentials}} when not is_nil(credentials) ->
            {:ok, credentials}
          _ ->
            {:error, :not_found}
        end

      # Otherwise, get application-wide credentials
      true ->
        case Application.get_env(:clinicpro, :zoom_api_credentials) do
          nil -> {:error, :missing_credentials}
          credentials -> {:ok, credentials}
        end
    end
  end

  defp generate_access_token(%{client_id: client_id, client_secret: client_secret}) do
    # For OAuth 2.0 Server-to-Server app
    url = "https://zoom.us/oauth/token"

    auth_header = "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
    headers = [
      {"Authorization", auth_header},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    body = "grant_type=account_credentials&account_id=#{client_id}"

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"access_token" => access_token}} ->
            {:ok, access_token}
          _ ->
            {:error, :invalid_token_response}
        end

      {:ok, response} ->
        {:error, response}

      error ->
        error
    end
  end

  defp generate_access_token(%{api_key: api_key, api_secret: api_secret}) do
    # For JWT app (legacy)
    # Generate a JWT token that expires in 1 hour
    current_time = System.system_time(:second)
    expiration_time = current_time + 3600

    header = %{
      "alg" => "HS256",
      "typ" => "JWT"
    }

    payload = %{
      "iss" => api_key,
      "exp" => expiration_time
    }

    header_json = Jason.encode!(header)
    payload_json = Jason.encode!(payload)

    header_encoded = Base.url_encode64(header_json, padding: false)
    payload_encoded = Base.url_encode64(payload_json, padding: false)

    signature_input = "#{header_encoded}.#{payload_encoded}"
    signature = :crypto.mac(:hmac, :sha256, api_secret, signature_input)
    signature_encoded = Base.url_encode64(signature, padding: false)

    token = "#{header_encoded}.#{payload_encoded}.#{signature_encoded}"
    {:ok, token}
  end

  defp create_zoom_meeting(token, _appointment, _opts) do
    url = "#{@zoom_api_base_url}/users/me/meetings"

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    # Format _appointment details for the meeting
    topic = format_meeting_topic(_appointment)
    start_time = format_meeting_start_time(_appointment)
    duration = _appointment.duration || 30

    body = Jason.encode!(%{
      topic: topic,
      type: 2, # Scheduled meeting
      start_time: start_time,
      duration: duration,
      timezone: "UTC",
      password: generate_meeting_password(),
      settings: %{
        host_video: true,
        participant_video: true,
        join_before_host: false,
        mute_upon_entry: true,
        waiting_room: true,
        meeting_authentication: false
      }
    })

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: status, body: response_body}} when status in 200..201 ->
        Jason.decode(response_body)

      {:ok, response} ->
        {:error, response}

      error ->
        error
    end
  end

  defp update_zoom_meeting(token, _appointment, meeting_data, _opts) do
    meeting_id = meeting_data[:meeting_id]

    if is_nil(meeting_id) do
      {:error, :missing_meeting_id}
    else
      url = "#{@zoom_api_base_url}/meetings/#{meeting_id}"

      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]

      # Format _appointment details for the meeting
      topic = format_meeting_topic(_appointment)
      start_time = format_meeting_start_time(_appointment)
      duration = _appointment.duration || 30

      body = Jason.encode!(%{
        topic: topic,
        start_time: start_time,
        duration: duration,
        timezone: "UTC"
      })

      case HTTPoison.patch(url, body, headers) do
        {:ok, %{status_code: 204}} ->
          # Zoom returns 204 No Content on successful update
          # We need to get the meeting details to return updated data
          get_zoom_meeting(token, meeting_id)

        {:ok, %{status_code: status, body: response_body}} when status in 200..201 ->
          Jason.decode(response_body)

        {:ok, response} ->
          {:error, response}

        error ->
          error
      end
    end
  end

  defp get_zoom_meeting(token, meeting_id) do
    url = "#{@zoom_api_base_url}/meetings/#{meeting_id}"

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        Jason.decode(response_body)

      {:ok, response} ->
        {:error, response}

      error ->
        error
    end
  end

  defp delete_zoom_meeting(token, meeting_data, _opts) do
    meeting_id = meeting_data[:meeting_id]

    if is_nil(meeting_id) do
      {:error, :missing_meeting_id}
    else
      url = "#{@zoom_api_base_url}/meetings/#{meeting_id}"

      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.delete(url, headers) do
        {:ok, %{status_code: status}} when status in [200, 204] ->
          {:ok, %{}}

        {:ok, response} ->
          {:error, response}

        error ->
          error
      end
    end
  end

  defp extract_meeting_data(_appointment) do
    case _appointment.meeting_data do
      nil -> %{}
      meeting_data when is_map(meeting_data) -> meeting_data
      _ -> %{}
    end
  end

  defp format_meeting_topic(_appointment) do
    patient_name = "#{_appointment.patient.first_name} #{_appointment.patient.last_name}"
    doctor_name = "#{_appointment.doctor.first_name} #{_appointment.doctor.last_name}"

    "ClinicPro: #{patient_name} _appointment with Dr. #{doctor_name}"
  end

  defp format_meeting_start_time(_appointment) do
    naive_datetime = NaiveDateTime.new!(
      _appointment.appointment_date,
      _appointment.appointment_time
    )

    # Convert to DateTime with UTC timezone
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")

    # Format as ISO8601 string (YYYY-MM-DDThh:mm:ssZ)
    DateTime.to_iso8601(datetime)
  end

  defp generate_meeting_password do
    # Generate a random 6-character password with letters and numbers
    :crypto.strong_rand_bytes(3)
    |> Base.encode16(case: :upper)
  end

  defp generate_token do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
