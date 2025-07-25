# ClinicPro Railway + GitHub Actions CI/CD Setup

## Overview

The deployment pipeline uses:
- **GitHub Actions** for CI: compile with `--warnings-as-errors`, run tests, build Docker image
- **Railway CLI** for deployment: deploy verified container to Railway infrastructure
- **Railway PostgreSQL** for database
- **GitHub Container Registry (GHCR)** for storing Docker images

This document describes the CI/CD pipeline setup using GitHub Actions and Railway CLI for deploying ClinicPro to Railway infrastructure. The new setup provides better control over the deployment process and catches compilation issues early in the CI pipeline.

## What's Been Implemented

### 1. Railway Configuration
- **Database**: PostgreSQL service added to Railway project
- **Registry**: GitHub Container Registry (ghcr.io)
- **Image**: `shelfwise-llc/clinicpro`
- **Environment Variables**: Configured for Phoenix production deployment

### 2. GitHub Actions CI/CD Pipeline
- **Location**: `.github/workflows/deploy.yml`
- **Triggers**: Push to main/master branch, Pull requests
- **Stages**:
  - **Test Stage**: Runs tests with PostgreSQL service, checks formatting, compiles with `--warnings-as-errors`
  - **Build & Deploy Stage**: Builds Docker image, pushes to GHCR, deploys with Railway CLI

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
- `bin/kamal` - Kamal CLI wrapper

## Next Steps

### 1. GitHub Repository Setup
1. Go to GitHub repository settings → Secrets and variables → Actions
2. Add the following secrets:
   ```
   DATABASE_URL=postgresql://username:password@host:port/database
   SECRET_KEY_BASE=<generate with mix phx.gen.secret>
   PAYSTACK_SECRET_KEY=<your paystack secret key>
   PAYSTACK_PUBLIC_KEY=<your paystack public key>
   RAILWAY_SERVER_HOST=<your railway app host>
   RAILWAY_PUBLIC_DOMAIN=<your railway app domain>
   ```

### 2. Railway Database Setup
1. Add a PostgreSQL database service to your Railway project
2. Copy the DATABASE_URL from Railway environment variables
3. Set the same DATABASE_URL in GitHub secrets

### 3. Deployment Process
The deployment now works as follows:
1. Push code to main branch
2. GitHub Actions runs tests and compilation checks
3. If tests pass, builds Docker image and pushes to GHCR
4. Kamal deploys the container to Railway infrastructure
5. Health checks ensure successful deployment

### 4. Manual Deployment
You can also deploy manually using:
```bash
# Set environment variables
export DATABASE_URL="your_database_url"
export SECRET_KEY_BASE="your_secret_key"
export PAYSTACK_SECRET_KEY="your_paystack_secret"
export PAYSTACK_PUBLIC_KEY="your_paystack_public"

# Deploy with Kamal
kamal deploy
```

## Benefits of This Approach

1. **Early Error Detection**: Compilation issues are caught in CI before deployment
2. **Consistent Builds**: Docker images are built in a clean environment
3. **Better Rollback**: Kamal provides easy rollback capabilities
4. **Environment Isolation**: Clear separation between CI and production environments
5. **Scalable**: Can easily extend to multiple environments (staging, production)

## Monitoring and Maintenance

- **Logs**: `kamal app logs` to view application logs
- **Status**: `kamal app status` to check deployment status
- **Rollback**: `kamal app rollback [VERSION]` to rollback if needed
- **Health Check**: Application includes `/health` endpoint for monitoring

## Current Status

✅ Kamal configuration completed
✅ GitHub Actions workflow created
✅ Compilation warnings fixed
✅ Code pushed to `kamal-deployment` branch
⏳ Awaiting GitHub secrets configuration
⏳ Awaiting Railway database setup
⏳ Ready for first deployment test

## Payment Integration Note

The system is now configured for **Paystack** payment processing (not M-Pesa as previously configured). The multi-tenant architecture remains the same, with each clinic having its own Paystack configuration.
