defmodule Clinicpro.VirtualMeetings.SimpleAdapter do
  @moduledoc """
  A simple virtual meeting adapter that generates meeting links without external API calls.

  This adapter is useful for development, testing, or as a fallback when no other
  adapter is configured. It can generate predictable meeting URLs based on appointment data
  or work with clinic-provided meeting links.
  """

  @behaviour Clinicpro.VirtualMeetings.Adapter
  require Logger

  @doc """
  Creates a new virtual meeting by generating a simple URL or using clinic-provided link.

  The URL is based on the configured base URL and includes the appointment ID
  and a random token for uniqueness. If the clinic has already provided a meeting link
  (e.g., from Google Meet), that link will be used instead.

  ## Parameters

  * `appointment` - The appointment for which to create a meeting
  * `opts` - Additional options including clinic-specific configuration

  ## Returns

  * `{:ok, %{url: url}}` - Returns a map with the generated meeting URL
  """
  @impl true
  def create_meeting(appointment, opts \\ []) do
    # Check if clinic has already provided a meeting link
    case get_clinic_provided_link(appointment, opts) do
      {:ok, url} ->
        # Use clinic-provided link (e.g., Google Meet link)
        {:ok,
         %{
           url: url,
           provider: get_provider_from_url(url),
           meeting_id: "clinic-provided-#{appointment.id}",
           created_at: DateTime.utc_now(),
           token: get_token_from_url(url)
         }}

      :error ->
        # Generate simple URL as fallback
        base_url = get_base_url()
        token = generate_token()
        url = "#{base_url}/#{appointment.id}/#{token}"

        {:ok,
         %{
           url: url,
           provider: "simple",
           meeting_id: "simple-#{appointment.id}-#{token}",
           created_at: DateTime.utc_now(),
           token: token
         }}
    end
  end

  @doc """
  Updates an existing virtual meeting.

  For the simple adapter, this just regenerates the meeting URL or preserves
  clinic-provided links.

  ## Parameters

  * `appointment` - The appointment with the meeting to update
  * `opts` - Additional options including clinic-specific configuration

  ## Returns

  * `{:ok, %{url: url}}` - Returns a map with the updated meeting URL
  """
  @impl true
  def update_meeting(appointment, opts \\ []) do
    # Check if the appointment already has a meeting_link with our base URL
    case appointment.meeting_link do
      link when is_binary(link) and link != "" ->
        # Extract token from the existing meeting link
        case extract_token_from_url(link) do
          {:ok, token} ->
            # Use the existing token
            base_url = get_base_url()
            url = "#{base_url}/#{appointment.id}/#{token}"

            {:ok,
             %{
               url: url,
               provider: "simple",
               meeting_id: "simple-#{appointment.id}-#{token}",
               created_at: DateTime.utc_now(),
               token: token
             }}
          
          :error ->
            # Generate a new meeting
            base_url = get_base_url()
            token = generate_token()
            url = "#{base_url}/#{appointment.id}/#{token}"

            {:ok,
             %{
               url: url,
               provider: "simple",
               meeting_id: "simple-#{appointment.id}-#{token}",
               created_at: DateTime.utc_now(),
               token: token
             }}
        end
      
      _ ->
        # Generate a new meeting
        base_url = get_base_url()
        token = generate_token()
        url = "#{base_url}/#{appointment.id}/#{token}"

        {:ok,
         %{
           url: url,
           provider: "simple",
           meeting_id: "simple-#{appointment.id}-#{token}",
           created_at: DateTime.utc_now(),
           token: token
         }}
    end
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
  def delete_meeting(appointment) do
    :ok
  end

  # Private functions

  defp get_clinic_provided_link(appointment, opts) do
    # Check if clinic has provided a meeting link in opts
    case Keyword.get(opts, :clinic_meeting_link) do
      nil ->
        # Check if appointment has a meeting link
        case Map.get(appointment, :meeting_link) do
          nil -> :error
          link when is_binary(link) and link != "" -> {:ok, link}
          _ -> :error
        end

      link when is_binary(link) and link != "" ->
        {:ok, link}

      _ ->
        :error
    end
  end

  defp get_provider_from_url(url) do
    cond do
      String.contains?(url, "meet.google.com") -> "google_meet"
      String.contains?(url, "zoom.us") -> "zoom"
      true -> "clinic_provided"
    end
  end

  defp get_base_url do
    Clinicpro.VirtualMeetings.Config.get_base_url()
  end

  defp generate_token do
    :crypto.strong_rand_bytes(8)
    |> Base.url_encode64(padding: false)
  end

  defp get_token_from_url(url) do
    # Extract token from URL path
    # Assuming URL format like https://meet.clinicpro.com/42/Ru5qItVGrks
    case String.split(url, "/") do
      [_scheme, _domain | path_parts] ->
        List.last(path_parts)
      _ ->
        generate_token()
    end
  end

  defp extract_token_from_url(url) do
    # Extract token from URL path
    # Assuming URL format like https://meet.clinicpro.com/42/Ru5qItVGrks
    case String.split(url, "/") do
      [_scheme, _domain | path_parts] ->
        {:ok, List.last(path_parts)}
      _ ->
        :error
    end
  end
end
