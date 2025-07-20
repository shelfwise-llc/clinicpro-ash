import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :clinicpro, Clinicpro.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "clinicpro_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :clinicpro, ClinicproWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "PdBs5WMFxWYf2INXa1R8rodSpgX536iv+sxU6O+aEOYrkJtWcpvsOJI7bkwPHLaj",
  server: false

# In test we don't send emails
config :clinicpro, Clinicpro.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure AshAuthentication for tests
config :clinicpro, :token_signing_secret, "test_secret_key_for_ash_authentication_tokens"

# Enable test bypass mode
config :clinicpro, :test_bypass_enabled, true

# Configure mock modules for tests
config :clinicpro, :accounts_api, Clinicpro.Mocks.Accounts
config :clinicpro, :appointments_api, Clinicpro.Mocks.Appointments
config :clinicpro, :auth_module, Clinicpro.Mocks.Accounts

# Bypass AshAuthentication compilation in tests
config :ash_authentication, :bypass_compile_time_checks, true

# Completely disable Ash resources in tests to avoid compilation issues
config :ash, :disable_async_creation, true
config :ash, :validate_api_config_inclusion, false
config :ash, :validate_api_resource_inclusion, false
