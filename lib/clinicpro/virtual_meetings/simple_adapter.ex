defmodule Clinicpro.VirtualMeetings.SimpleAdapter do
  @moduledoc """
  A simple virtual meeting adapter that generates meeting links without external API calls.

  This adapter is useful for development, testing, or as a fallback when no other
  adapter is configured. It generates predictable meeting URLs based on appointment data.
  """

  @behaviour Clinicpro.VirtualMeetings.Adapter

  @doc """
  Creates a new virtual meeting by generating a simple URL.

  The URL is based on the configured base URL and includes the appointment ID
  and a random token for uniqueness.

  ## Parameters

  * `appointment` - The appointment for which to create a meeting
  * `opts` - Additional options (unused in this adapter)

  ## Returns

  * `{:ok, %{url: url}}` - Returns a map with the generated meeting URL
  """
  @impl true
  def create_meeting(appointment, _opts \\ []) do
    base_url = get_base_url()
    token = generate_token()

    url = "#{base_url}/#{appointment.id}/#{token}"

    {:ok, %{
      url: url,
      provider: "simple",
      meeting_id: "simple-#{appointment.id}-#{token}",
      created_at: DateTime.utc_now()
    }}
  end

  @doc """
  Updates an existing virtual meeting.

  For the simple adapter, this just regenerates the meeting URL.

  ## Parameters

  * `appointment` - The appointment with the meeting to update
  * `opts` - Additional options (unused in this adapter)

  ## Returns

  * `{:ok, %{url: url}}` - Returns a map with the updated meeting URL
  """
  @impl true
  def update_meeting(appointment, opts \\ []) do
    create_meeting(appointment, opts)
  end

  @doc """
  Deletes an existing virtual meeting.

  For the simple adapter, this is a no-op since no external resources are created.

  ## Parameters

  * `appointment` - The appointment with the meeting to delete

  ## Returns

  * `:ok` - Always returns :ok
  """
  @impl true
  def delete_meeting(_appointment) do
    :ok
  end

  # Private functions

  defp get_base_url do
    Application.get_env(:clinicpro, :virtual_meeting_base_url, "https://meet.clinicpro.com")
  end

  defp generate_token do
    :crypto.strong_rand_bytes(8)
    |> Base.url_encode64(padding: false)
  end
end
