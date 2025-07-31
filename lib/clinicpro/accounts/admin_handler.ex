defmodule Clinicpro.Accounts.AdminHandler do
  @moduledoc """
  Handles admin-related business logic and orchestration.
  """

  alias Clinicpro.Accounts.{AdminService, AdminFinder}

  @doc """
  Handles admin login with magic link validation.
  """
  def handle_magic_link_login(token, clinic_id) do
    case AdminFinder.find_by_magic_link_token(token, clinic_id) do
      {:ok, admin} ->
        {:ok, admin}

      {:error, :not_found} ->
        {:error, :invalid_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Initiates magic link for admin login.
  """
  def initiate_magic_link(email, clinic_id) do
    case AdminFinder.find_by_email(email, clinic_id) do
      {:ok, admin} ->
        case AdminService.generate_magic_link(admin) do
          {:ok, token, magic_link} ->
            {:ok, admin, token, magic_link}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        {:error, :user_not_found}
        {:ok, :email_sent}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Handles admin logout.
  """
  def logout(admin_id) do
    AdminService.invalidate_session(admin_id)
  end
end
