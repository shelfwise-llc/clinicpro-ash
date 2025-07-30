#!/bin/bash

echo "🚂 Railway Project Token Generator for CI/CD"
echo "=========================================="
echo ""
echo "This script will help you generate a new Railway Project Token for CI/CD."
echo ""

# Check if Railway CLI is installed and logged in
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
    echo "❌ No project linked to this directory. Linking project..."
    
    # List available projects
    echo "Available projects:"
    railway list
    
    # Prompt for project selection
    echo ""
    echo "Enter the project name to link (from the list above):"
    read PROJECT_NAME
    
    # Link the project
    railway link "$PROJECT_NAME"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to link project. Please try again."
        exit 1
    fi
    
    PROJECT_INFO=$(railway status)
fi

# Extract project and environment info
PROJECT_NAME=$(echo "$PROJECT_INFO" | grep "Project:" | cut -d' ' -f2)
ENVIRONMENT=$(echo "$PROJECT_INFO" | grep "Environment:" | cut -d' ' -f2)
SERVICE=$(echo "$PROJECT_INFO" | grep "Service:" | cut -d' ' -f2)

echo "✅ Current project: $PROJECT_NAME"
echo "✅ Environment: $ENVIRONMENT"
echo "✅ Service: $SERVICE"
echo ""

# Instructions for creating a Project Token
echo "To create a new Project Token for CI/CD, follow these steps:"
echo ""
echo "1. Go to Railway Dashboard: https://railway.app/project/$PROJECT_NAME/settings/tokens"
echo "2. Click 'New Token'"
echo "3. Select 'Project Token'"
echo "4. Give it a name like 'GitHub Actions CI/CD'"
echo "5. Copy the generated token"
echo ""

# Prompt for the token
echo "Enter the newly created Project Token:"
read -s PROJECT_TOKEN
echo ""

if [ -z "$PROJECT_TOKEN" ]; then
    echo "❌ No token provided. Exiting."
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI is not installed. Please install it first."
    echo "You can set the token manually as a GitHub secret:"
    echo "gh secret set RAILWAY_TOKEN --body \"$PROJECT_TOKEN\""
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub. Please login first:"
    echo "gh auth login"
    echo ""
    echo "You can set the token manually as a GitHub secret:"
    echo "gh secret set RAILWAY_TOKEN --body \"$PROJECT_TOKEN\""
    exit 1
fi

# Set the GitHub secret
echo "Setting GitHub secret RAILWAY_TOKEN..."
gh secret set RAILWAY_TOKEN --body "$PROJECT_TOKEN"

if [ $? -eq 0 ]; then
    echo "✅ Successfully set GitHub secret RAILWAY_TOKEN"
    echo ""
    echo "To trigger a deployment, run:"
    echo "git add ."
    echo "git commit -m \"Update Railway token and trigger deployment\""
    echo "git push origin main"
    echo ""
    echo "Or use the trigger_deployment.sh script if available."
else
    echo "❌ Failed to set GitHub secret. Please set it manually:"
    echo "gh secret set RAILWAY_TOKEN --body \"$PROJECT_TOKEN\""
fi
