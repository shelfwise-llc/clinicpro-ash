defmodule ClinicproWeb.PageController do
  use ClinicproWeb, :controller

  def home(conn, _params) do
    # The home page is custom made, so skip the default app layout
    # but still set a proper page title
    conn
    |> assign(:page_title, "ClinicPro - Healthcare Management System")
    |> render(:home, layout: false)
  end
end
