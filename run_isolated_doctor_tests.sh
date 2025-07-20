#!/bin/bash

# This script runs the isolated doctor flow tests without loading the main application
# This avoids AshAuthentication compilation issues

echo "Running isolated doctor flow tests..."
elixir test/doctor_flow_runner.exs

# Exit with the same status as the test runner
exit $?
