# Script to run a minimal Phoenix server with the bypass controller
# This avoids compiling the problematic AshAuthentication code

# Load the application configuration
Application.put_env(:phoenix, :serve_endpoints, true)
Application.put_env(:clinicpro, ClinicproWeb.Endpoint, server: true)

# Start required applications
Application.ensure_all_started(:phoenix)
Application.ensure_all_started(:phoenix_pubsub)
Application.ensure_all_started(:phoenix_html)
Application.ensure_all_started(:telemetry)
Application.ensure_all_started(:plug_cowboy)
Application.ensure_all_started(:jason)

# Define a minimal router that only includes the bypass routes
defmodule ClinicproWeb.MinimalRouter do
  use Phoenix.Router
  import ClinicproWeb.RouterBypass

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", ClinicproWeb do
    pipe_through :browser

    get "/", DoctorFlowBypassController, :index
    doctor_flow_bypass_routes()
  end
end

# Define a minimal endpoint
defmodule ClinicproWeb.MinimalEndpoint do
  use Phoenix.Endpoint, otp_app: :clinicpro

  socket "/socket", ClinicproWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  plug Plug.Static,
    at: "/",
    from: :clinicpro,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  plug Plug.Session,
    store: :cookie,
    key: "_clinicpro_key",
    signing_salt: "random_salt"

  plug ClinicproWeb.MinimalRouter
end

# Start the endpoint
{:ok, _} = Supervisor.start_link([ClinicproWeb.MinimalEndpoint], strategy: :one_for_one)

# Keep the VM running
Process.sleep(:infinity)
