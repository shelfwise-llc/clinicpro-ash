defmodule ClinicproWeb.MagicLinkLive do
  @moduledoc """
  LiveView for magic link authentication.

  This LiveView handles the magic link authentication flow,
  including sending magic links and processing token validation.
  """
  use ClinicproWeb, :live_view

  alias Clinicpro.Auth.Handlers.MagicLinkHandler

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, :magic_link), email_sent: false, error: nil)}
  end

  @impl true
  def handle_event("send_magic_link", %{"magic_link" => %{"email" => email}}, socket) do
    case MagicLinkHandler.initiate(email) do
      {:ok, :email_sent} ->
        {:noreply, assign(socket, email_sent: true, error: nil)}

      {:error, reason} ->
        {:noreply,
         assign(socket, email_sent: false, error: "Failed to send magic link: #{reason}")}
    end
  end

  @impl true
  def handle_event("validate", %{"magic_link" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, :magic_link))}
  end
end
