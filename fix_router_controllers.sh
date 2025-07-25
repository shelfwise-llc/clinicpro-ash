#!/bin/bash

# Script to fix router controller references with duplicate ClinicproWeb prefixes
set -e

echo "=== ClinicPro Router Controller Fix ==="
echo "This script will fix controller references in the router.ex file"
echo

# Check if we're in the right directory
if [ ! -f "mix.exs" ]; then
  echo "Error: This script must be run from the root of the ClinicPro project"
  exit 1
fi

ROUTER_FILE="lib/clinicpro_web/router.ex"

if [ ! -f "$ROUTER_FILE" ]; then
  echo "Error: Router file not found at $ROUTER_FILE"
  exit 1
fi

# Create a backup of the router file
echo "Creating backup of router.ex..."
cp "$ROUTER_FILE" "${ROUTER_FILE}.bak"
echo "✅ Backup created at ${ROUTER_FILE}.bak"
echo

# Fix the controller references with duplicate ClinicproWeb prefixes
echo "Fixing controller references..."
sed -i 's/ClinicproWeb\.ClinicproWeb\./ClinicproWeb\./g' "$ROUTER_FILE"
echo "✅ Fixed duplicate ClinicproWeb prefixes"
echo

# Check for any remaining issues
echo "Checking for remaining issues..."
grep -n "ClinicproWeb\.ClinicproWeb" "$ROUTER_FILE" || echo "✅ No remaining duplicate prefixes found"
echo

echo "=== Router Controller Fix Complete ==="
echo "Run 'mix compile' to verify the fixes"

# Make the script executable
chmod +x fix_router_controllers.sh
