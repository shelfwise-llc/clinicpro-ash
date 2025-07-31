#!/bin/bash

# This script helps you generate a Railway Project Token and set it as a GitHub secret
# for use in CI/CD pipelines.

echo "🚂 Railway Project Token Generator"
echo "================================="
echo ""
echo "This script will help you generate a Railway Project Token and set it as a GitHub secret."
echo "IMPORTANT: We need a PROJECT TOKEN (not an Account Token) for CI/CD deployments."
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI is not installed. Please install it first:"
    echo "curl -fsSL https://railway.app/install.sh | sh"
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Railway
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please login first:"
    echo "railway login"
    exit 1
fi

# Check if logged in to GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Not logged in to GitHub. Please login first:"
    echo "gh auth login"
    exit 1
fi

# Get project info
PROJECT_INFO=$(railway status 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "No Railway project linked to this directory. Let's link one."
    railway link
    if [ $? -ne 0 ]; then
        echo "❌ Failed to link Railway project. Please try again manually."
        exit 1
    fi
    PROJECT_INFO=$(railway status)
fi

# Extract project and environment info
PROJECT_NAME=$(echo "$PROJECT_INFO" | grep "Project:" | cut -d' ' -f2)
ENVIRONMENT=$(echo "$PROJECT_INFO" | grep "Environment:" | cut -d' ' -f2)
SERVICE_NAME=$(echo "$PROJECT_INFO" | grep "Service:" | cut -d' ' -f2)

echo "✅ Linked to Railway project: $PROJECT_NAME ($ENVIRONMENT)"
echo "✅ Service: $SERVICE_NAME"
echo ""

# Instructions for creating a Project Token
echo "To create a new Project Token for CI/CD, follow these steps:"
echo ""
echo "1. Go to Railway Dashboard: https://railway.app/project"
echo "2. Select your project: $PROJECT_NAME"
echo "3. Go to Settings > Tokens"
echo "4. Click 'New Token'"
echo "5. Select 'Project Token'"
echo "6. Give it a name like 'GitHub Actions CI/CD'"
echo "7. Copy the generated token"
echo ""

# Prompt for the token
echo "Enter the newly created Project Token:"
read -s PROJECT_TOKEN
echo ""

if [ -z "$PROJECT_TOKEN" ]; then
    echo "❌ No token provided. Exiting."
    exit 1
fi

# Set the token as a GitHub secret
echo "Setting the token as a GitHub secret..."
echo "$PROJECT_TOKEN" | gh secret set RAILWAY_TOKEN

if [ $? -ne 0 ]; then
    echo "❌ Failed to set GitHub secret."
    exit 1
fi

echo "✅ GitHub secret RAILWAY_TOKEN set successfully!"
echo ""
echo "Your Railway Project Token has been set as a GitHub secret."
echo "You can now use it in your GitHub Actions workflow."
echo ""
echo "To test the deployment, run:"
echo "gh workflow run deploy.yml --ref cleanup/mpesa-removal"

