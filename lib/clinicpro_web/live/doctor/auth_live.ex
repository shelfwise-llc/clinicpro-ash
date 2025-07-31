defmodule ClinicproWeb.Doctor.AuthLive do
  @moduledoc """
  LiveView for doctor authentication with magic link flow.
  """

  use ClinicproWeb, :live_view
  alias Clinicpro.Accounts.DoctorHandler

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       email: "",
       loading: false,
       message: nil,
       message_type: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case params["token"] do
      nil ->
        # Show magic link form
        {:noreply, socket}

      token ->
        # Validate token and login
        handle_token_validation(token, socket)
    end
  end

  @impl true
  def handle_event("send_magic_link", %{"email" => email}, socket) do
    case DoctorHandler.initiate_magic_link(email, socket.assigns.clinic_id || 1) do
      {:ok, _doctor, _token, _magic_link} ->
        {:noreply,
         assign(socket,
           message: "Magic link sent to your email!",
           message_type: :success,
           loading: false
         )}

      {:ok, :email_sent} ->
        {:noreply,
         assign(socket,
           message: "If an account exists, you'll receive an email shortly.",
           message_type: :success,
           loading: false
         )}

      {:error, reason} ->
        {:noreply,
         assign(socket,
           message: "Error: #{inspect(reason)}",
           message_type: :error,
           loading: false
         )}
    end
  end

  @impl true
  def handle_event("validate_email", %{"email" => email}, socket) do
    if valid_email?(email) do
      {:noreply, assign(socket, email: email, message: nil)}
    else
      {:noreply,
       assign(socket, message: "Please enter a valid email address", message_type: :error)}
    end
  end

  defp handle_token_validation(token, socket) do
    case DoctorHandler.handle_magic_link_login(token, socket.assigns.clinic_id || 1) do
      {:ok, doctor} ->
        session_data = %{
          doctor_id: doctor.id,
          email: doctor.email,
          clinic_id: doctor.clinic_id,
          login_at: DateTime.utc_now()
        }

        {:noreply,
         socket
         |> put_flash(:info, "Welcome back, Dr. #{doctor.name}!")
         |> redirect(to: ~p"/doctor/dashboard")}

      {:error, :token_expired} ->
        {:noreply,
         assign(socket,
           message: "This magic link has expired. Please request a new one.",
           message_type: :error
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           message: "Invalid or expired magic link.",
           message_type: :error
         )}
    end
  end

  defp valid_email?(email) do
    email =~ ~r/^[^\s]+@[^\s]+$/
  end
end
