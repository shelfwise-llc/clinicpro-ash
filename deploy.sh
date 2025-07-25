#!/bin/bash

# ClinicPro Railway Deployment Script
# Usage: ./deploy.sh "Your commit message"

# Check if commit message is provided
if [ -z "$1" ]; then
  echo "Error: Please provide a commit message"
  echo "Usage: ./deploy.sh \"Your commit message\""
  exit 1
fi

COMMIT_MESSAGE="$1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting ClinicPro deployment process...${NC}"

# Step 1: Add all changes to git
echo -e "${YELLOW}Adding changes to git...${NC}"
git add .
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to add files to git${NC}"
  exit 1
fi
echo -e "${GREEN}Changes added successfully${NC}"

# Step 2: Commit changes
echo -e "${YELLOW}Committing changes with message: ${COMMIT_MESSAGE}${NC}"
git commit -m "$COMMIT_MESSAGE"
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to commit changes${NC}"
  exit 1
fi
echo -e "${GREEN}Changes committed successfully${NC}"

# Step 3: Push to GitHub
echo -e "${YELLOW}Pushing changes to GitHub...${NC}"
git push origin main
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to push changes to GitHub${NC}"
  exit 1
fi
echo -e "${GREEN}Changes pushed to GitHub successfully${NC}"

# Step 4: Run pre-deployment checks
echo -e "${YELLOW}Running pre-deployment checks...${NC}"

# Check if mix compiles successfully
echo -e "${YELLOW}Checking compilation...${NC}"
mix compile
if [ $? -ne 0 ]; then
  echo -e "${RED}Compilation failed. Please fix the errors before deploying.${NC}"
  exit 1
fi
echo -e "${GREEN}Compilation successful${NC}"

# Check if tests pass
echo -e "${YELLOW}Running critical tests...${NC}"
mix test --only critical
if [ $? -ne 0 ]; then
  echo -e "${YELLOW}Warning: Some critical tests failed. Proceed with caution.${NC}"
  read -p "Do you want to continue with deployment? (y/n): " continue_deploy
  if [ "$continue_deploy" != "y" ]; then
    echo -e "${YELLOW}Deployment aborted by user${NC}"
    exit 1
  fi
fi

# Step 5: Deploy to Railway
echo -e "${YELLOW}Deploying to Railway...${NC}"
# Check if project is linked
railway status > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "${YELLOW}Project not linked. Linking to ClinicPro project...${NC}"
  railway link --project 77c00a97-4d76-42e6-827f-e8a61a64642b
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to link project${NC}"
    exit 1
  fi
fi

# Check for required environment variables
echo -e "${YELLOW}Checking environment variables...${NC}"

# List of required environment variables for ClinicPro
REQUIRED_VARS=("SECRET_KEY_BASE" "DATABASE_URL" "PHX_HOST")

# Check if variables are set in Railway
for var in "${REQUIRED_VARS[@]}"; do
  railway variables get "$var" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Environment variable $var is not set in Railway${NC}"
    read -p "Do you want to set it now? (y/n): " set_var
    if [ "$set_var" = "y" ]; then
      read -p "Enter value for $var: " var_value
      railway variables set "$var"="$var_value"
    fi
  fi
done

# Deploy using Railway CLI
echo -e "${YELLOW}Deploying using Railway CLI...${NC}"
railway up
if [ $? -ne 0 ]; then
  echo -e "${RED}Deployment failed${NC}"
  exit 1
fi

# Get the deployment URL
DEPLOY_URL=$(railway domain | grep -o 'https://[^ ]*')

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Your application is available at: ${DEPLOY_URL}${NC}"
echo ""
echo -e "${YELLOW}Available routes:${NC}"
echo -e "- Admin: ${DEPLOY_URL}/admin"
echo -e "- Admin Bypass: ${DEPLOY_URL}/admin_bypass"
echo -e "- Patient Portal: ${DEPLOY_URL}/patient"
echo -e "- Doctor Portal: ${DEPLOY_URL}/doctor"
