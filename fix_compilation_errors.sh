#!/bin/bash

# Script to check and fix compilation errors in ClinicPro before deployment
set -e

echo "=== ClinicPro Compilation Error Checker ==="
echo "This script will help identify and fix compilation errors before deployment"
echo

# Check if we're in the right directory
if [ ! -f "mix.exs" ]; then
  echo "Error: This script must be run from the root of the ClinicPro project"
  exit 1
fi

# Step 1: Clean any previous build artifacts
echo "Step 1: Cleaning previous build artifacts..."
mix deps.clean --all
mix clean
rm -rf _build
echo "✅ Clean completed"
echo

# Step 2: Get dependencies
echo "Step 2: Getting dependencies..."
mix deps.get
echo "✅ Dependencies retrieved"
echo

# Step 3: Check for compilation warnings (but don't fail on warnings)
echo "Step 3: Checking for compilation warnings..."
mix compile > compilation_output.txt 2>&1
cat compilation_output.txt
echo "✅ Compilation check completed"
echo

# Step 4: Extract warnings for easy fixing
echo "Step 4: Extracting warnings for fixing..."
grep -n "warning:" compilation_output.txt > warnings.txt
echo "✅ Warnings extracted to warnings.txt"
echo

# Step 5: Check database connection
echo "Step 5: Checking database connection..."
echo "Make sure your database is running and properly configured in config/dev.exs"
echo "Current DATABASE_URL: $DATABASE_URL"
echo

# Step 6: Verify health endpoint
echo "Step 6: Verifying health endpoint..."
echo "You can run the server with: mix phx.server"
echo "Then check the health endpoint at: http://localhost:4000/health"
echo

# Step 7: Prepare for Railway deployment
echo "Step 7: Preparing for Railway deployment..."
echo "1. Make sure you have the Railway CLI installed and logged in"
echo "2. Link your project with: railway link"
echo "3. Set the DATABASE_URL with: railway variables --set \"DATABASE_URL=postgresql://postgres:PASSWORD@HOST:PORT/railway\""
echo "4. Deploy with: railway up"
echo

echo "=== Compilation Error Check Complete ==="
echo "Fix the warnings in warnings.txt before deploying to Railway"
echo "Run this script again after fixing to verify all issues are resolved"

# Make the script executable
chmod +x fix_compilation_errors.sh
