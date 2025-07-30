#!/bin/bash

echo "🚀 Comprehensive Railway Deployment Test"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo "1. Checking Git status..."
git status --porcelain
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Git repository is accessible${NC}"
    echo "Current branch: $(git branch --show-current)"
    echo "Last commit: $(git log -1 --oneline)"
else
    echo -e "${RED}❌ Git repository issue${NC}"
fi

echo ""
echo "2. Checking Railway CLI..."
if command -v railway &> /dev/null; then
    echo -e "${GREEN}✅ Railway CLI is installed${NC}"
    railway --version
    
    # Check authentication
    if railway whoami &> /dev/null; then
        echo -e "${GREEN}✅ Railway CLI is authenticated${NC}"
        railway whoami
    else
        echo -e "${RED}❌ Railway CLI not authenticated${NC}"
        echo "Please run: railway login"
    fi
    
    # Check project status
    echo ""
    echo "Project status:"
    railway status 2>/dev/null || echo -e "${YELLOW}⚠️ Project not linked or authentication failed${NC}"
    
else
    echo -e "${RED}❌ Railway CLI not found${NC}"
    echo "Installing Railway CLI..."
    curl -fsSL https://railway.app/install.sh | sh
    export PATH="$HOME/.railway/bin:$PATH"
fi

echo ""
echo "3. Checking GitHub CLI..."
if command -v gh &> /dev/null; then
    echo -e "${GREEN}✅ GitHub CLI is installed${NC}"
    gh --version
    
    # Check authentication
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✅ GitHub CLI is authenticated${NC}"
        
        # Check secrets
        echo ""
        echo "GitHub secrets:"
        gh secret list
        
        if gh secret list | grep -q "RAILWAY_TOKEN"; then
            echo -e "${GREEN}✅ RAILWAY_TOKEN secret exists${NC}"
        else
            echo -e "${RED}❌ RAILWAY_TOKEN secret not found${NC}"
        fi
        
    else
        echo -e "${RED}❌ GitHub CLI not authenticated${NC}"
        echo "Please run: gh auth login"
    fi
else
    echo -e "${RED}❌ GitHub CLI not found${NC}"
fi

echo ""
echo "4. Checking GitHub Actions workflow..."
if [ -f ".github/workflows/deploy.yml" ]; then
    echo -e "${GREEN}✅ Deployment workflow exists${NC}"
    echo "Workflow file: .github/workflows/deploy.yml"
    
    # Check recent workflow runs
    echo ""
    echo "Recent workflow runs:"
    gh run list --limit 5 2>/dev/null || echo -e "${YELLOW}⚠️ Cannot access workflow runs${NC}"
else
    echo -e "${RED}❌ Deployment workflow not found${NC}"
fi

echo ""
echo "5. Checking application compilation..."
if mix compile 2>/dev/null; then
    echo -e "${GREEN}✅ Application compiles successfully${NC}"
else
    echo -e "${YELLOW}⚠️ Compilation issues detected${NC}"
fi

echo ""
echo "6. Testing Railway deployment (dry run)..."
if command -v railway &> /dev/null && railway whoami &> /dev/null; then
    echo "Testing Railway CLI deployment..."
    # This would be a dry run - we're not actually deploying
    echo "Command that would be executed: railway up --detach"
    echo -e "${YELLOW}⚠️ Skipping actual deployment for safety${NC}"
else
    echo -e "${RED}❌ Cannot test Railway deployment - CLI not authenticated${NC}"
fi

echo ""
echo "=== Test Summary ==="
echo "✅ Check the output above for any issues"
echo "✅ If all components are working, you can trigger a deployment by:"
echo "   1. Ensuring RAILWAY_TOKEN is set as a GitHub secret"
echo "   2. Pushing changes to main branch"
echo "   3. Monitoring the GitHub Actions workflow"

echo ""
echo "🔗 Useful links:"
echo "   - GitHub Actions: https://github.com/$(gh repo view --json owner,name --jq '.owner.login + \"/\" + .name')/actions"
echo "   - Railway Dashboard: https://railway.app/project/77c00a97-4d76-42e6-827f-e8a61a64642b"
