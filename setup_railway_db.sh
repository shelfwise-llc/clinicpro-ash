#!/bin/bash

# Exit on error
set -e

echo "Setting up PostgreSQL database on Railway for ClinicPro"
echo "======================================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "Railway CLI not found. Please install it first."
    echo "npm i -g @railway/cli"
    exit 1
fi

# Check if we're logged in to Railway
railway whoami || {
    echo "Please login to Railway first using 'railway login'"
    exit 1
}

# Check if we're linked to a project
railway status || {
    echo "Please link to your Railway project first using 'railway link'"
    exit 1
}

echo "Adding PostgreSQL database to Railway project..."
echo "This will open an interactive prompt. Please select PostgreSQL when prompted."
echo "Press Enter to continue..."
read

# Add PostgreSQL database
railway add

# Get the current DATABASE_URL
current_db_url=$(railway variables | grep DATABASE_URL | awk '{print $3}')

echo "Current DATABASE_URL: [redacted for security]"

# Check if we need to update the DATABASE_URL
if [[ "$current_db_url" == *"localhost"* ]]; then
    echo "DATABASE_URL is pointing to localhost. We need to update it."
    echo "Please go to the Railway dashboard and update the DATABASE_URL variable to use the PostgreSQL connection string."
    echo "Railway dashboard URL: https://railway.app/dashboard"
    echo ""
    echo "After updating the DATABASE_URL, redeploy the application using:"
    echo "railway up"
else
    echo "DATABASE_URL appears to be correctly set to a non-localhost value."
    echo "Redeploying the application..."
    railway up
fi

echo ""
echo "Setup complete! Check the Railway dashboard for deployment status."
echo "Railway dashboard URL: https://railway.app/dashboard"
