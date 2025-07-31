#!/bin/bash

# verify_deployment.sh - Script to verify deployment health
# This script checks if the ClinicPro application is deployed and running correctly

set -e  # Exit on error

# Default to Railway production URL if not specified
DEPLOY_URL=${1:-"https://clinicpro-ash-production.up.railway.app"}

echo "🔍 ClinicPro Deployment Verification"
echo "===================================="
echo "Checking deployment at: $DEPLOY_URL"
echo

# Function to check HTTP status code
check_endpoint() {
  local url=$1
  local expected_code=${2:-200}
  local description=$3
  
  echo -n "Checking $description ($url)... "
  
  local response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  
  if [ "$response" -eq "$expected_code" ]; then
    echo "✅ Success ($response)"
    return 0
  else
    echo "❌ Failed (Expected: $expected_code, Got: $response)"
    return 1
  fi
}

# Function to check health endpoint with detailed output
check_health() {
  local url="$DEPLOY_URL/health"
  
  echo "Checking health endpoint ($url)..."
  
  # Get both status code and response body
  local temp_file=$(mktemp)
  local status_code=$(curl -s -w "%{http_code}" -o "$temp_file" "$url")
  local response=$(cat "$temp_file")
  rm "$temp_file"
  
  echo "Status code: $status_code"
  
  if [ "$status_code" -eq 200 ]; then
    echo "✅ Health check passed"
    echo "Response: $response"
    return 0
  else
    echo "❌ Health check failed"
    echo "Response: $response"
    return 1
  fi
}

# Check if Railway CLI is available
if command -v railway &> /dev/null; then
  echo "Railway CLI is available. Checking deployment status..."
  railway status
  echo
fi

# Check main endpoints
echo "Checking critical endpoints..."
check_health
check_endpoint "$DEPLOY_URL" 200 "Home page"
check_endpoint "$DEPLOY_URL/doctor" 200 "Doctor portal"
check_endpoint "$DEPLOY_URL/admin/login" 200 "Admin login"
check_endpoint "$DEPLOY_URL/patient/request-otp" 200 "Patient OTP request"

echo
echo "Deployment verification complete!"
