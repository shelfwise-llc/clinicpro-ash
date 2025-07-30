# ClinicPro Railway CI/CD Deployment Setup

## Overview
This document describes the ClinicPro application's CI/CD pipeline using GitHub Actions and Railway CLI for automated deployment.

## 1. Infrastructure Setup

### Railway Configuration
- **Project**: Currently linked to `desirable-integrity` project
- **Service**: `clinicpro-ash`
- **Environment**: Production environment with proper secrets management
- **Database**: PostgreSQL service configured in Railway

### GitHub Configuration
- **Workflow**: `.github/workflows/deploy.yml`
- **Triggers**: Push to main/master branch, Pull requests, manual workflow_dispatch
- **Container**: Uses official Railway CLI Docker container (`ghcr.io/railwayapp/cli:latest`)

## 2. GitHub Actions CI/CD Pipeline
- **Location**: `.github/workflows/deploy.yml`
- **Triggers**: Push to main/master branch, Pull requests
- **Stages**:
  - **Test Stage**: Runs tests with PostgreSQL service, checks formatting, compiles with warnings
  - **Build & Deploy Stage**: Deploys with Railway CLI Docker container which directly builds from Dockerfile

## 3. Environment Configuration
- **Required Variables**:
  - `RAILWAY_TOKEN` - Railway Project Token (NOT Account Token)
  - `DATABASE_URL` - PostgreSQL connection string
  - `SECRET_KEY_BASE` - Phoenix secret key
  - `PAYSTACK_SECRET_KEY` - Payment integration
  - `PAYSTACK_PUBLIC_KEY` - Payment integration

## 4. Railway Token Setup (CRITICAL)
- **Token Type**: Must use a Project Token (NOT an Account Token)
- **Token Creation**:
  1. Go to Railway Dashboard: https://railway.app/project
  2. Select your project
  3. Go to Settings > Tokens
  4. Click "New Token"
  5. Select "Project Token"
  6. Give it a name like "GitHub Actions CI/CD"
  7. Copy the generated token
- **Token Format**: Should look like `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
- **Helper Script**: Run `./generate_railway_token.sh` to create and set up the token

## 5. Helper Scripts
- `generate_railway_token.sh` - Interactive script to create and set up Railway Project Token
- `test_deployment.sh` - Verify Railway CLI installation, authentication, and deployment setup
- `trigger_deployment.sh` - Automate pushing changes and triggering GitHub Actions workflow

## Next Steps

### 1. Configure GitHub Secrets
Create the following secrets in GitHub repository settings:

```bash
# Railway project token (NOT account token)
RAILWAY_TOKEN=your_railway_project_token

# Database URL from Railway PostgreSQL service
DATABASE_URL=your_railway_database_url

# Phoenix secret key base
SECRET_KEY_BASE=your_secret_key_base

# Payment integration keys
PAYSTACK_SECRET_KEY=your_paystack_secret
PAYSTACK_PUBLIC_KEY=your_paystack_public
```

### 2. Test Deployment
After setting up secrets, the deployment should automatically trigger on pushes to main branch.

## 3. Deployment Process
The deployment now works as follows:
1. Push code to main branch
2. GitHub Actions runs tests and compilation checks
3. If tests pass, Railway CLI directly builds and deploys from Dockerfile
4. Health checks ensure successful deployment

## Manual Deployment
You can also deploy manually using:

```bash
# Set environment variables
export RAILWAY_TOKEN="your_railway_project_token"
export DATABASE_URL="your_database_url"
export SECRET_KEY_BASE="your_secret_key_base"
export PAYSTACK_SECRET_KEY="your_paystack_secret"
export PAYSTACK_PUBLIC_KEY="your_paystack_public"

# Deploy with Railway CLI
railway up --detach
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "Project Token not found" Error
- **Issue**: The Railway CLI cannot find a valid Project Token
- **Solutions**:
  - Verify the `RAILWAY_TOKEN` secret is set in GitHub
  - Ensure it's a Project Token (not an Account Token)
  - Regenerate a new Project Token using `./generate_railway_token.sh`
  - Check token format (should be UUID format)
  - Verify the token has permissions for the correct project

#### 2. "Unauthorized. Please login with railway login" Error
- **Issue**: The Railway CLI is trying to use interactive login instead of token
- **Solutions**:
  - Ensure `RAILWAY_TOKEN` environment variable is set
  - Set `CI=true` environment variable (already done in workflow)
  - Do not use `railway link` in CI environment
  - Use the Docker container approach as configured

#### 3. Formatting Errors in CI
- **Issue**: The test stage fails due to formatting issues
- **Solutions**:
  - Run `mix format` locally before pushing
  - Check the specific files mentioned in the error
  - Fix formatting issues in those files

#### 4. Git Submodule Errors
- **Issue**: "No url found for submodule path 'assets/demo' in .gitmodules"
- **Solutions**:
  - Remove the submodule reference if not needed
  - Update .gitmodules file with correct submodule URL
  - Initialize submodules in the workflow

### Debugging Tools

#### 1. Check Deployment Status
```bash
# View recent workflow runs
gh run list --workflow="deploy.yml" --limit 3

# View detailed logs of a failed run
gh run view <RUN_ID> --log-failed
```

#### 2. Verify Railway Configuration
```bash
# Check current project
railway status

# List available projects
railway list

# Test authentication
railway whoami
```

#### 3. Run Test Scripts
```bash
# Test deployment prerequisites
./test_deployment.sh

# Trigger a test deployment
./trigger_deployment.sh
```

## Benefits of This Approach

1. **Early Error Detection**: Compilation issues are caught in CI before deployment
2. **Direct Deployment**: Railway CLI directly builds and deploys from Dockerfile
3. **Environment Isolation**: Clear separation between CI and production environments
4. **Scalable**: Can easily extend to multiple environments (staging, production)

## Monitoring and Maintenance

- **Logs**: Railway dashboard to view application logs
- **Status**: Railway CLI status command to check deployment status
- **Health Check**: Application includes `/health` endpoint for monitoring

## Current Status

✅ Railway CLI configuration completed
✅ GitHub Actions workflow created
✅ Compilation warnings fixed
✅ Code ready for deployment
⏳ Awaiting GitHub secrets configuration
⏳ Awaiting Railway database setup
⏳ Ready for first deployment test
