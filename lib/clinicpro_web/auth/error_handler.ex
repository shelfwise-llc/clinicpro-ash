defmodule ClinicproWeb.Auth.ErrorHandler do
  @moduledoc """
  Error handler for Guardian authentication failures.

  This module handles authentication errors and redirects users
  to the appropriate pages based on the error type.
  """
  import Plug.Conn
  import Phoenix.Controller

  @doc """
  Handle authentication errors.
  """
  def auth_error(conn, {type, _reason}, _opts) do
    case type do
      :unauthenticated ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: Routes.auth_path(conn, :new))
        |> halt()

      :unauthorized ->
        conn
        |> put_status(:forbidden)
        |> put_view(ClinicproWeb.ErrorView)
        |> render(:"403")
        |> halt()

      _ ->
        conn
        |> put_status(:unauthorized)
        |> put_view(ClinicproWeb.ErrorView)
        |> render(:"401")
        |> halt()
    end
  end
end
