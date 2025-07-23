defmodule Clinicpro.VirtualMeetings.GoogleMeetAdapter do
  @moduledoc """
  Google Meet adapter for virtual meetings.

  This adapter creates, updates, and deletes Google Meet meetings using the Google Calendar API.
  It requires Google API credentials to be configured in the application environment.
  """

  @behaviour Clinicpro.VirtualMeetings.Adapter

  require Logger
  alias Clinicpro.AdminBypass.Appointment
  alias Clinicpro.Repo
  alias GoogleApi.Calendar.V3.Api.Events
  alias GoogleApi.Calendar.V3.Model.{Event, EventDateTime, ConferencingData, CreateConferenceRequest, ConferenceData, ConferenceSolution}
  alias Goth.Token

  @doc """
  Creates a new Google Meet meeting for an appointment.

  ## Parameters

  * `appointment` - The appointment to create a meeting for
  * `opts` - Additional options for the meeting creation

  ## Returns

  * `{:ok, meeting_data}` - On success, returns meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def create_meeting(appointment, opts \\ []) do
    with {:ok, appointment} <- get_appointment_with_associations(appointment),
         {:ok, client} <- get_google_client(),
         {:ok, event} <- create_calendar_event(client, appointment, opts) do

      # Extract meeting details from the created event
      meeting_data = %{
        url: event.hangoutLink,
        token: generate_token(),
        provider: "google_meet",
        meeting_id: event.id,
        created_at: DateTime.utc_now(),
        event_id: event.id,
        calendar_id: get_calendar_id(opts)
      }

      {:ok, meeting_data}
    else
      {:error, %{status: status, body: body}} ->
        Logger.error("Google Calendar API error: #{status} - #{inspect(body)}")
        {:error, "Failed to create Google Meet meeting: #{status}"}

      {:error, reason} ->
        Logger.error("Failed to create Google Meet meeting: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Updates an existing Google Meet meeting.

  ## Parameters

  * `appointment` - The appointment with the meeting to update
  * `opts` - Additional options for the meeting update

  ## Returns

  * `{:ok, meeting_data}` - On success, returns updated meeting data
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def update_meeting(appointment, opts \\ []) do
    with {:ok, appointment} <- get_appointment_with_associations(appointment),
         {:ok, client} <- get_google_client(),
         meeting_data <- extract_meeting_data(appointment),
         {:ok, event} <- update_calendar_event(client, appointment, meeting_data, opts) do

      # Extract updated meeting details
      updated_meeting_data = %{
        url: event.hangoutLink,
        provider: "google_meet",
        meeting_id: event.id,
        updated_at: DateTime.utc_now(),
        event_id: event.id,
        calendar_id: meeting_data[:calendar_id] || get_calendar_id(opts)
      }

      {:ok, Map.merge(meeting_data, updated_meeting_data)}
    else
      {:error, %{status: status, body: body}} ->
        Logger.error("Google Calendar API error: #{status} - #{inspect(body)}")
        {:error, "Failed to update Google Meet meeting: #{status}"}

      {:error, reason} ->
        Logger.error("Failed to update Google Meet meeting: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Deletes an existing Google Meet meeting.

  ## Parameters

  * `appointment` - The appointment with the meeting to delete
  * `opts` - Additional options for the meeting deletion

  ## Returns

  * `:ok` - On success
  * `{:error, reason}` - On failure, returns an error reason
  """
  @impl true
  def delete_meeting(appointment, opts \\ []) do
    with {:ok, appointment} <- get_appointment_with_associations(appointment),
         {:ok, client} <- get_google_client(),
         meeting_data <- extract_meeting_data(appointment),
         {:ok, _response} <- delete_calendar_event(client, meeting_data, opts) do
      :ok
    else
      {:error, %{status: status, body: body}} ->
        Logger.error("Google Calendar API error: #{status} - #{inspect(body)}")
        {:error, "Failed to delete Google Meet meeting: #{status}"}

      {:error, reason} ->
        Logger.error("Failed to delete Google Meet meeting: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp get_appointment_with_associations(%Appointment{} = appointment) do
    appointment = Repo.preload(appointment, [:patient, :doctor, :clinic])
    {:ok, appointment}
  end

  defp get_appointment_with_associations(appointment_id) when is_integer(appointment_id) do
    case Appointment.get_appointment(appointment_id) do
      {:ok, appointment} -> get_appointment_with_associations(appointment)
      error -> error
    end
  end

  defp get_google_client do
    case get_token() do
      {:ok, token} ->
        conn = GoogleApi.Calendar.V3.Connection.new(token.token)
        {:ok, conn}
      error -> error
    end
  end

  defp get_token do
    case Application.get_env(:clinicpro, :google_api_credentials) do
      nil ->
        {:error, :missing_credentials}

      %{json: json} when is_binary(json) ->
        # Use credentials JSON directly
        Goth.start_link(
          name: CalendarToken,
          source: {:service_account, json, scopes: ["https://www.googleapis.com/auth/calendar"]}
        )
        Goth.fetch(CalendarToken)

      %{} = credentials ->
        # Convert credentials map to JSON
        json = Jason.encode!(credentials)
        Goth.start_link(
          name: CalendarToken,
          source: {:service_account, json, scopes: ["https://www.googleapis.com/auth/calendar"]}
        )
        Goth.fetch(CalendarToken)

      _ ->
        {:error, :invalid_credentials}
    end
  end

  defp create_calendar_event(client, appointment, opts) do
    calendar_id = get_calendar_id(opts)

    # Format appointment details for the event
    summary = format_event_summary(appointment)
    description = format_event_description(appointment)
    start_time = format_event_start_time(appointment)
    end_time = format_event_end_time(appointment)

    # Create event with Google Meet conferencing
    event = %Event{
      summary: summary,
      description: description,
      start: %EventDateTime{
        dateTime: start_time,
        timeZone: "UTC"
      },
      end: %EventDateTime{
        dateTime: end_time,
        timeZone: "UTC"
      },
      conferenceData: %ConferenceData{
        createRequest: %CreateConferenceRequest{
          requestId: "#{appointment.id}-#{:os.system_time(:millisecond)}",
          conferenceSolutionKey: %{
            type: "hangoutsMeet"
          }
        }
      },
      attendees: [
        %{email: appointment.patient.email},
        %{email: appointment.clinic.email}
      ]
    }

    Events.calendar_events_insert(
      client,
      calendar_id,
      body: event,
      conferenceDataVersion: 1
    )
  end

  defp update_calendar_event(client, appointment, meeting_data, opts) do
    calendar_id = meeting_data[:calendar_id] || get_calendar_id(opts)
    event_id = meeting_data[:event_id]

    if is_nil(event_id) do
      {:error, :missing_event_id}
    else
      # Get existing event
      case Events.calendar_events_get(client, calendar_id, event_id) do
        {:ok, existing_event} ->
          # Update event details
          summary = format_event_summary(appointment)
          description = format_event_description(appointment)
          start_time = format_event_start_time(appointment)
          end_time = format_event_end_time(appointment)

          updated_event = %{existing_event |
            summary: summary,
            description: description,
            start: %EventDateTime{
              dateTime: start_time,
              timeZone: "UTC"
            },
            end: %EventDateTime{
              dateTime: end_time,
              timeZone: "UTC"
            }
          }

          Events.calendar_events_update(
            client,
            calendar_id,
            event_id,
            body: updated_event
          )

        error -> error
      end
    end
  end

  defp delete_calendar_event(client, meeting_data, opts) do
    calendar_id = meeting_data[:calendar_id] || get_calendar_id(opts)
    event_id = meeting_data[:event_id]

    if is_nil(event_id) do
      {:error, :missing_event_id}
    else
      Events.calendar_events_delete(client, calendar_id, event_id)
    end
  end

  defp extract_meeting_data(appointment) do
    case appointment.meeting_data do
      nil -> %{}
      meeting_data when is_map(meeting_data) -> meeting_data
      _ -> %{}
    end
  end

  defp format_event_summary(appointment) do
    patient_name = "#{appointment.patient.first_name} #{appointment.patient.last_name}"
    doctor_name = "#{appointment.doctor.first_name} #{appointment.doctor.last_name}"

    "ClinicPro: #{patient_name} appointment with Dr. #{doctor_name}"
  end

  defp format_event_description(appointment) do
    """
    Virtual appointment via Google Meet

    Patient: #{appointment.patient.first_name} #{appointment.patient.last_name}
    Doctor: #{appointment.doctor.first_name} #{appointment.doctor.last_name}
    Clinic: #{appointment.clinic.name}
    Date: #{Calendar.strftime(appointment.appointment_date, "%B %d, %Y")}
    Time: #{Calendar.strftime(appointment.appointment_time, "%H:%M")}
    Duration: #{appointment.duration} minutes

    This is an automatically generated meeting link for a ClinicPro virtual appointment.
    """
  end

  defp format_event_start_time(appointment) do
    naive_datetime = NaiveDateTime.new!(
      appointment.appointment_date,
      appointment.appointment_time
    )

    # Convert to DateTime with UTC timezone
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")
    DateTime.to_iso8601(datetime)
  end

  defp format_event_end_time(appointment) do
    naive_datetime = NaiveDateTime.new!(
      appointment.appointment_date,
      appointment.appointment_time
    )

    # Add appointment duration in minutes
    end_naive_datetime = NaiveDateTime.add(naive_datetime, appointment.duration * 60, :second)

    # Convert to DateTime with UTC timezone
    datetime = DateTime.from_naive!(end_naive_datetime, "Etc/UTC")
    DateTime.to_iso8601(datetime)
  end

  defp get_calendar_id(opts) do
    # Check if calendar_id is provided in options
    case Keyword.get(opts, :calendar_id) do
      nil ->
        # Use default calendar ID from config or "primary" as fallback
        Application.get_env(:clinicpro, :google_calendar_id, "primary")
      calendar_id -> calendar_id
    end
  end

  defp generate_token do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
