defmodule ClinicproWeb.AuthController do
  @moduledoc """
  Controller for authentication actions.

  Handles login, logout, and password reset functionality with
  multi-tenant support via clinic_id.
  """
  use ClinicproWeb, :controller

  alias Clinicpro.Accounts
  alias Clinicpro.Accounts.AuthUser
  alias Clinicpro.Auth.Guardian

  @doc """
  Renders the login form.
  """
  def new(conn, _params) do
    # Get all clinics for the clinic selector
    clinics = Accounts.list_clinics()
    |> Enum.map(fn clinic -> {clinic.name, clinic.id} end)
    
    conn
    |> assign(:clinics, clinics)
    |> assign(:show_clinic_selector, true)
    |> assign(:error_message, nil)
    |> render("new.html")
  end

  @doc """
  Handles the login form submission.
  """
  def create(conn, %{"auth" => auth_params}) do
    %{"email" => email, "password" => password} = auth_params
    clinic_id = Map.get(auth_params, "clinic_id")
    
    # Try to get the user by email and password
    case Accounts.get_auth_user_by_email_and_password(email, password) do
      nil ->
        # Authentication failed
        clinics = Accounts.list_clinics()
        |> Enum.map(fn clinic -> {clinic.name, clinic.id} end)
        
        conn
        |> assign(:clinics, clinics)
        |> assign(:show_clinic_selector, true)
        |> assign(:error_message, "Invalid email or password")
        |> render("new.html")
        
      user ->
        # Check if user is admin or if they belong to the selected clinic
        cond do
          user.role == "admin" ->
            # Admin user can access any clinic
            conn
            |> Guardian.Plug.sign_in(user)
            |> put_flash(:info, "Welcome back, admin!")
            |> redirect(to: "/admin")
            
          is_nil(clinic_id) ->
            # Regular user must select a clinic
            clinics = Accounts.list_clinics()
            |> Enum.map(fn clinic -> {clinic.name, clinic.id} end)
            
            conn
            |> assign(:clinics, clinics)
            |> assign(:show_clinic_selector, true)
            |> assign(:error_message, "Please select a clinic")
            |> render("new.html")
            
          user.clinic_id == clinic_id ->
            # User belongs to the selected clinic
            conn
            |> Guardian.Plug.sign_in(user)
            |> put_flash(:info, "Welcome back!")
            |> redirect(to: "/")
            
          true ->
            # User doesn't belong to the selected clinic
            clinics = Accounts.list_clinics()
            |> Enum.map(fn clinic -> {clinic.name, clinic.id} end)
            
            conn
            |> assign(:clinics, clinics)
            |> assign(:show_clinic_selector, true)
            |> assign(:error_message, "You don't have access to the selected clinic")
            |> render("new.html")
        end
    end
  end

  @doc """
  Logs out the current user.
  """
  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: Routes.auth_path(conn, :new))
  end

  @doc """
  Renders the forgot password page.
  """
  def forgot_password(conn, _params) do
    render(conn, "forgot_password.html")
  end

  @doc """
  Handles the forgot password form submission.
  """
  def send_reset_password_instructions(conn, %{"auth" => %{"email" => email}}) do
    # Always return success to prevent email enumeration
    if user = Accounts.get_auth_user_by_email(email) do
      # Generate a reset token
      {:ok, token} = Accounts.generate_auth_user_reset_password_token(user)
      
      # Send the reset email
      url = Routes.auth_url(conn, :reset_password, token)
      Clinicpro.Email.deliver_reset_password_instructions(user, url)
    end
    
    conn
    |> put_flash(:info, "If your email is in our system, you will receive reset instructions shortly")
    |> redirect(to: Routes.auth_path(conn, :new))
  end

  @doc """
  Renders the reset password page.
  """
  def reset_password(conn, %{"token" => token}) do
    case Accounts.get_auth_user_by_reset_password_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Reset password link is invalid or has expired")
        |> redirect(to: Routes.auth_path(conn, :new))
        
      user ->
        changeset = Accounts.change_auth_user_password(user)
        conn
        |> assign(:token, token)
        |> assign(:user, user)
        |> assign(:changeset, changeset)
        |> render("reset_password.html")
    end
  end

  @doc """
  Handles the reset password form submission.
  """
  def update_password(conn, %{"token" => token, "auth" => auth_params}) do
    case Accounts.get_auth_user_by_reset_password_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Reset password link is invalid or has expired")
        |> redirect(to: Routes.auth_path(conn, :new))
        
      user ->
        case Accounts.reset_auth_user_password(user, auth_params) do
          {:ok, _user} ->
            conn
            |> put_flash(:info, "Password reset successfully. Please sign in with your new password.")
            |> redirect(to: Routes.auth_path(conn, :new))
            
          {:error, changeset} ->
            conn
            |> assign(:token, token)
            |> assign(:user, user)
            |> assign(:changeset, changeset)
            |> render("reset_password.html")
        end
    end
  end
end
