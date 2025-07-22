#!/bin/bash

# This script runs the isolated doctor flow controller tests
# without compiling the main application

# Set environment variables to bypass AshAuthentication
export ASH_AUTHENTICATION_BYPASS_COMPILE_TIME_CHECKS=true
export CLINICPRO_TEST_BYPASS_ENABLED=true

# Run the isolated test file
elixir -r test/clinicpro_web/controllers/doctor_flow_isolated_test.exs -e "ExUnit.start(); ExUnit.run()"
