defmodule ClinicproWeb.HealthController do
  use ClinicproWeb, :controller

  @doc """
  Simple health check endpoint to verify the application is running.
  """
  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", timestamp: DateTime.utc_now()}))
  end
end
