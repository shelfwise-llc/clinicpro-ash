# Load API behaviours first
Code.require_file("support/api_behaviours.ex", __DIR__)

# Load our bypass test helper
Code.require_file("support/bypass_test_helper.exs", __DIR__)

# Load our mock modules
Code.require_file("support/mocks/accounts.ex", __DIR__)
Code.require_file("support/mocks/appointments.ex", __DIR__)
Code.require_file("support/bypass_ash_compilation.ex", __DIR__)

# Set up the Ash compilation bypass
Clinicpro.TestBypass.AshCompilation.setup()

# Start ExUnit with custom tag configuration
ExUnit.start(
  exclude: [slow: true],
  include: [critical: true]
)

# Configure Ecto sandbox mode
Ecto.Adapters.SQL.Sandbox.mode(Clinicpro.Repo, :manual)

# Configure Mox for mocking
Application.ensure_all_started(:mox)

# Define mocks for our API behaviours
Mox.defmock(Clinicpro.MockAccountsAPI, for: Clinicpro.AccountsAPIBehaviour)
Mox.defmock(Clinicpro.MockAppointmentsAPI, for: Clinicpro.AppointmentsAPIBehaviour)

# Configure Mox for global mode (allows expectations to be defined in setup blocks)
Mox.set_mode(Clinicpro.MockAccountsAPI, :global)
Mox.set_mode(Clinicpro.MockAppointmentsAPI, :global)

# Set up the test bypass
Clinicpro.TestBypass.Setup.setup()
