#!/bin/bash

# Exit on any error
set -e

echo "Verifying deployment..."

# Check health endpoint
echo "Checking health endpoint..."
curl -f https://clinicpro-ash-production.up.railway.app/health
echo -e "\nHealth endpoint: OK"

# Check main page
echo "Checking main page..."
curl -f https://clinicpro-ash-production.up.railway.app/
echo -e "\nMain page: OK"

# Check doctor portal
echo "Checking doctor portal..."
curl -f https://clinicpro-ash-production.up.railway.app/doctor
echo -e "\nDoctor portal: OK"

# Check admin portal (should redirect to login)
echo "Checking admin portal..."
curl -s -o /dev/null -w "%{http_code}" https://clinicpro-ash-production.up.railway.app/admin | grep -q "302"
echo -e "\nAdmin portal: OK (redirects to login as expected)"

# Check patient portal
echo "Checking patient portal..."
curl -f https://clinicpro-ash-production.up.railway.app/patient/request-otp
echo -e "\nPatient portal: OK"

echo -e "\n✅ All endpoints are working correctly!"
echo "✅ Deployment successful!"
