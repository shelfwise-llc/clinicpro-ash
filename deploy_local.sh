#!/bin/bash

echo "🚂 Testing Railway CLI Deployment Locally"
echo "========================================"
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI is not installed. Please install it first:"
    echo "curl -fsSL https://railway.app/install.sh | sh"
    exit 1
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please login first:"
    echo "railway login"
    exit 1
fi

# Get current project info
PROJECT_INFO=$(railway status 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ No project linked to this directory."
    exit 1
fi

# Extract project and environment info
PROJECT_NAME=$(echo "$PROJECT_INFO" | grep "Project:" | cut -d' ' -f2)
ENVIRONMENT=$(echo "$PROJECT_INFO" | grep "Environment:" | cut -d' ' -f2)
SERVICE=$(echo "$PROJECT_INFO" | grep "Service:" | cut -d' ' -f2)

echo "✅ Current project: $PROJECT_NAME"
echo "✅ Environment: $ENVIRONMENT"
echo "✅ Service: $SERVICE"
echo ""

# Use existing Railway authentication
echo "Using existing Railway authentication..."
echo ""
if [ $? -ne 0 ]; then
    echo "❌ Token test failed. The token might be invalid or expired."
    exit 1
fi

echo "✅ Token test successful!"
echo ""

# Ask for confirmation before deploying
echo "Ready to deploy to Railway using the token."
echo "This will deploy the current directory to Railway project: $PROJECT_NAME"
echo ""
read -p "Do you want to proceed with deployment? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Deploy to Railway
echo "Deploying to Railway..."
railway up --detach

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo ""
    echo "Your application should now be available at:"
    echo "https://clinicpro-ash-production.up.railway.app"
else
    echo "❌ Deployment failed."
    exit 1
fi
