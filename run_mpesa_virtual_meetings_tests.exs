#!/usr/bin/env elixir

# This script runs the M-Pesa and Virtual Meetings integration tests
# It can be run with: mix run run_mpesa_virtual_meetings_tests.exs

# Load Mix environment
Mix.start()
Mix.shell().info("Running M-Pesa and Virtual Meetings integration tests...")

# Run the tests
ExUnit.start()
Code.require_file("test/clinicpro/integration/mpesa_virtual_meetings_test.exs")

# Print a message when done
Mix.shell().info("M-Pesa and Virtual Meetings integration tests completed.")
