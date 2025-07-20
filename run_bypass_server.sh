#!/bin/bash

# Script to run the bypass server for doctor flow testing
# This avoids the AshAuthentication compilation issues

echo "Starting ClinicPro bypass server for doctor flow testing..."
echo "This server bypasses AshAuthentication to allow testing the doctor flow"
echo "Access the doctor flow at: http://localhost:4000/doctor/appointments"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run the bypass server script
elixir run_bypass_server.exs
