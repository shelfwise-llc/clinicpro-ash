defmodule ClinicproWeb.HealthController do
  use ClinicproWeb, :controller
  alias Clinicpro.Repo

  @doc """
  Enhanced health check endpoint to verify the application is running and database is connected.
  Returns:
  - 200 OK if everything is working
  - 500 Internal Server Error if database connection fails
  """
  def check(conn, _params) do
    try do
      # Try to query the database to verify connection
      {:ok, _unused} = Repo.query("SELECT 1")

      # Get database connection info for diagnostics
      db_info = %{
        host: System.get_env("DATABASE_URL") |> String.replace(~r/.*@([^:]+).*/, "\\1"),
        connected: true
      }

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{
          status: "ok",
          timestamp: DateTime.utc_now(),
          app_name: "ClinicPro",
          environment: System.get_env("MIX_ENV") || "dev",
          database: db_info
        })
      )
    rescue
      e ->
        # Log the error and return a 500 response
        require Logger
        Logger.error("Health check failed: #{inspect(e)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          500,
          Jason.encode!(%{
            status: "error",
            timestamp: DateTime.utc_now(),
            error: "Database connection failed: #{inspect(e)}",
            # Redact password
            database_url: System.get_env("DATABASE_URL") |> String.replace(~r/:[^:]+@/, ":****@")
          })
        )
    end
  end
end
