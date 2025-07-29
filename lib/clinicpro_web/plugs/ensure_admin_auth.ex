defmodule ClinicproWeb.Plugs.EnsureAdminAuth do
  @moduledoc """
  Plug to ensure the user is authenticated as an admin.
  Redirects to login page if not authenticated.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias ClinicproWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    # Check if admin is logged in via session
    case get_session(conn, :admin_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in as an admin to access this page.")
        |> redirect(to: Routes.admin_path(conn, :login))
        |> halt()
      _admin_id ->
        conn
    end
  end
end
