#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up Railway CLI...${NC}"

# Check if Railway CLI is already installed
if command -v railway &> /dev/null; then
  echo -e "${GREEN}Railway CLI is already installed${NC}"
else
  echo -e "${YELLOW}Installing Railway CLI...${NC}"
  # Install Railway CLI
  curl -fsSL https://railway.app/install.sh | sh
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install Railway CLI${NC}"
    exit 1
  fi
  echo -e "${GREEN}Railway CLI installed successfully${NC}"
fi

# Login to Railway
echo -e "${YELLOW}Logging in to Railway...${NC}"
railway login

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to login to Railway${NC}"
  exit 1
fi

echo -e "${GREEN}Successfully logged in to Railway${NC}"

# Link to the project
echo -e "${YELLOW}Linking to ClinicPro project...${NC}"
railway link --project 77c00a97-4d76-42e6-827f-e8a61a64642b

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to link to project${NC}"
  exit 1
fi

echo -e "${GREEN}Successfully linked to ClinicPro project${NC}"
echo -e "${YELLOW}Railway CLI setup complete!${NC}"
