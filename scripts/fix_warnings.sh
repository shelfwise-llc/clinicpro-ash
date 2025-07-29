#!/bin/bash

# Script to fix common warnings in the codebase
# This will help resolve issues that prevent compilation with --warnings-as-errors

echo "=== Fixing unused variable warnings ==="

# Fix unused variables by adding underscore prefix
find lib -name "*.ex" -type f -exec sed -i 's/\bappointment\b\s*->/\_appointment ->/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/\bdoctors\s*=\s*/\_doctors = /g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/\bpatients\s*=\s*/\_patients = /g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/\bupdated\b\s*->/\_updated ->/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/\bopts\b\s*)/\_opts)/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/\bclinic_id\b\s*$/\_clinic_id/g' {} \;

echo "=== Fixing underscore variable usage warnings ==="

# Fix underscored variables that are used
find lib -name "*.ex" -type f -exec sed -i 's/_active\b/active/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/_clinic_id\b/clinic_id/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/_appointment\b/appointment/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/_page\b/page/g' {} \;

echo "=== Removing unused private functions ==="

# Comment out unused private functions
find lib -name "*.ex" -type f -exec sed -i 's/^  defp get_admins do/  # Unused function\n  # defp get_admins do/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/^  defp get_appointments do/  # Unused function\n  # defp get_appointments do/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/^  defp get_doctors do/  # Unused function\n  # defp get_doctors do/g' {} \;
find lib -name "*.ex" -type f -exec sed -i 's/^  defp get_patients do/  # Unused function\n  # defp get_patients do/g' {} \;

echo "=== Fixing missing module aliases ==="

# Add missing module aliases
find lib -name "payment_processor.ex" -type f -exec sed -i 's/alias Clinicpro.PaystackLegacy.{Transaction, Config}/alias Clinicpro.PaystackLegacy.{Transaction, Config}\nalias Clinicpro.Invoices\nalias Clinicpro.Clinics\nalias Clinicpro.Appointments\nalias Clinicpro.Appointments.Appointment\nalias Clinicpro.Paystack/g' {} \;

echo "=== Running formatter ==="
cd /home/alex/Projects/Sandbox/Clones_new/clinicpro && mix format

echo "=== Done! ==="
echo "Now run the check_compilation.sh script to see if the warnings are fixed."
