defmodule Clinicpro.VirtualMeetings.SimpleAdapter do
  @moduledoc """
  A simple virtual meeting adapter that generates meeting links without external API calls.

  This adapter is useful for development, testing, or as a fallback when no other
  adapter is configured. It generates predictable meeting URLs based on _appointment data.
  """

  @behaviour Clinicpro.VirtualMeetings.Adapter

  @doc """
  Creates a new virtual meeting by generating a simple URL.

  The URL is based on the configured base URL and includes the _appointment ID
  and a random token for uniqueness.

  ## Parameters

  * `_appointment` - The _appointment for which to create a meeting
  * `_opts` - Additional options (unused in this adapter)

  ## Returns

  * `{:ok, %{url: url}}` - Returns a map with the generated meeting URL
  """
  @impl true
  def create_meeting(_appointment, _opts \\ []) do
    base_url = get_base_url()
    token = generate_token()

    url = "#{base_url}/#{_appointment.id}/#{token}"

    {:ok, %{
      url: url,
      provider: "simple",
      meeting_id: "simple-#{_appointment.id}-#{token}",
      created_at: DateTime.utc_now()
    }}
  end

  @doc """
  Updates an existing virtual meeting.

  For the simple adapter, this just regenerates the meeting URL.

  ## Parameters

  * `_appointment` - The _appointment with the meeting to update
  * `_opts` - Additional options (unused in this adapter)

  ## Returns

  * `{:ok, %{url: url}}` - Returns a map with the updated meeting URL
  """
  @impl true
  def update_meeting(_appointment, _opts \\ []) do
    create_meeting(_appointment, _opts)
  end

  @doc """
  Deletes an existing virtual meeting.

  For the simple adapter, this is a no-op since no external resources are created.

  ## Parameters

  * `_appointment` - The _appointment with the meeting to delete

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
