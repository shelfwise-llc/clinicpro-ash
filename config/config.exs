# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :clinicpro,
  ecto_repos: [Clinicpro.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_apis: [
    Clinicpro.Accounts,
    Clinicpro.Clinics,
    Clinicpro.Appointments,
    Clinicpro.Patients,
    Clinicpro.Prescriptions
  ]

# Disable Ash API resource inclusion warnings
config :ash, :validate_api_resource_inclusion?, false
config :ash, :validate_api_config_inclusion?, false

# Configures the endpoint
config :clinicpro, ClinicproWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ClinicproWeb.ErrorHTML, json: ClinicproWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Clinicpro.PubSub,
  live_view: [signing_salt: "ZA3Yb6Ug"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :clinicpro, Clinicpro.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  clinicpro: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Guardian configuration for JWT authentication
config :clinicpro, Clinicpro.Auth.Guardian,
  issuer: "clinicpro",
  secret_key:
    System.get_env("GUARDIAN_SECRET_KEY") ||
      "dev_only_guardian_secret_key_please_change_in_production_at_least_64_bytes_long",
  ttl: {30, :day}

# Configure JSON:API
config :ash_json_api,
  router: ClinicproWeb.Router,
  json_encoder: Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  clinicpro: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  clinicpro: [
    args: [
      "js/app.js",
      "--bundle",
      "--target=es2017",
      "--outdir=../priv/static/assets",
      "--external:/fonts/*",
      "--external:/images/*",
      "--loader:.js=jsx",
      "--loader:.png=file",
      "--loader:.jpg=file",
      "--loader:.svg=file",
      "--loader:.woff=file",
      "--loader:.woff2=file",
      "--loader:.ttf=file",
      "--loader:.eot=file"
    ],
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian DB configuration for token storage

# GuardianDB configuration
config :guardian, Guardian.DB,
  repo: Clinicpro.Repo,
  # default
  schema_name: "guardian_tokens",
  # store refresh tokens
  token_types: ["refresh_token"],
  # 60 minutes
  sweep_interval: 60

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
