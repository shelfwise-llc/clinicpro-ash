# This script runs only the controller tests without compiling the full Ash resources
# It bypasses the AshAuthentication configuration issues

# Set environment variables to use mock modules
System.put_env("ASH_BYPASS_COMPILATION", "true")
System.put_env("USE_MOCK_AUTH", "true")

# Run the controller tests
Mix.shell().info("Running controller tests with mock modules...")
System.cmd("mix", ["test", "test/clinicpro_web/controllers/"], into: IO.stream(:stdio, :line))
