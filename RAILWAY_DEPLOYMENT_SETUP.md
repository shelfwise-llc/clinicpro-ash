# ClinicPro Railway CI/CD Deployment Setup

## Overview
This document describes the ClinicPro application's CI/CD pipeline using GitHub Actions and Railway CLI for automated deployment.

## 1. Infrastructure Setup

### Railway Configuration
- **Project ID**: `77c00a97-4d76-42e6-827f-e8a61a64642b`
- **Database**: PostgreSQL service configured in Railway
- **Environment**: Production environment with proper secrets management

### GitHub Configuration
- **Workflow**: `.github/workflows/deploy.yml`
- **Triggers**: Push to main/master branch, Pull requests
- **Registry**: GitHub Container Registry (ghcr.io) - Not used with current approach

### 2. GitHub Actions CI/CD Pipeline
- **Location**: `.github/workflows/deploy.yml`
- **Triggers**: Push to main/master branch, Pull requests
- **Stages**:
  - **Test Stage**: Runs tests with PostgreSQL service, checks formatting, compiles with `--warnings-as-errors`
  - **Build & Deploy Stage**: Deploys with Railway CLI which directly builds from Dockerfile

### 3. Environment Configuration
- **Secrets File**: `.kamal/secrets` (configured for environment variable injection)
- **Required Variables**:
  - `DATABASE_URL` - PostgreSQL connection string
  - `SECRET_KEY_BASE` - Phoenix secret key
  - `PAYSTACK_SECRET_KEY` - Payment integration
  - `PAYSTACK_PUBLIC_KEY` - Payment integration

### 4. Compilation Fixes
- Fixed `input_name/2` function call in ErrorHelpers
- Resolved underscored variable warnings throughout the codebase
- Fixed variable naming consistency in controllers and plugs

### 5. Helper Scripts
- `setup_kamal_railway.sh` - Environment setup guide
- `fix_compilation_warnings.sh` - Automated warning fixes
- `bin/kamal` - Kamal CLI wrapper (deprecated)

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
