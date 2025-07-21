#!/usr/bin/env elixir

# This script starts a minimal Phoenix server that only serves the admin bypass routes
# It avoids the broader application's compilation issues related to AshAuthentication

# Add the project's ebin directory to the code path
Code.prepend_path("_build/dev/lib/clinicpro/ebin")

# Start required applications
Application.ensure_all_started(:phoenix)
Application.ensure_all_started(:phoenix_html)
Application.ensure_all_started(:ecto)
Application.ensure_all_started(:postgrex)

# Configure the Repo
Application.put_env(:clinicpro, Clinicpro.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "clinicpro_dev",
  hostname: "localhost",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true
)

# Start the Repo
Clinicpro.Repo.start_link()

# Configure the Endpoint
Application.put_env(:clinicpro, ClinicproWeb.Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: String.duplicate("a", 64),
  live_view: [signing_salt: String.duplicate("a", 32)],
  pubsub_server: Clinicpro.PubSub,
  render_errors: [
    formats: [html: ClinicproWeb.ErrorHTML, json: ClinicproWeb.ErrorJSON],
    layout: false
  ],
  server: true
)

# Start the Endpoint
ClinicproWeb.Endpoint.start_link()

# Keep the script running
Process.sleep(:infinity)
