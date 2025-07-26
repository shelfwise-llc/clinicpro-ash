defmodule ClinicproWeb.AuthController do
  @moduledoc """
  Authentication controller for ClinicPro.

  This controller handles authentication-related actions such as sign-in and sign-out.
  It integrates with AshAuthentication for magic link authentication.
  """
  use ClinicproWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, _activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> redirect(to: return_to)
  end

  def failure(conn, _activity, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end
end
