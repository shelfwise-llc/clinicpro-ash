# This file contains test-specific configuration that overrides the main test.exs
# It's used to bypass AshAuthentication compilation issues during tests

import Config

# Completely disable AshAuthentication in tests
config :ash_authentication, :bypass_compile_time_checks, true

# Configure mock modules for tests
config :clinicpro, :accounts_api, Clinicpro.TestBypass.MockAccounts
config :clinicpro, :appointments_api, Clinicpro.TestBypass.MockAppointments
config :clinicpro, :auth_module, Clinicpro.TestBypass.MockAuth

# Enable test bypass mode
config :clinicpro, :test_bypass_enabled, true

# Disable Ash resource validation in tests
config :ash, :disable_async_creation, true
config :ash, :validate_api_config_inclusion, false
config :ash, :validate_api_resource_inclusion, false
