# ClinicPro Railway Deployment Guide

This guide documents the steps for successfully deploying ClinicPro to Railway based on previous successful deployments.

## Prerequisites

1. Railway CLI installed and logged in
2. GitHub repository with the ClinicPro application
3. Railway project and service created
4. Required environment variables configured

## Environment Variables

Ensure these environment variables are set in your Railway project:

```
DATABASE_URL=postgresql://postgres:password@ballast.proxy.rlwy.net:38267/railway
PHX_HOST=clinicpro-ash-production.up.railway.app
PHX_SERVER=true
PORT=4000
SECRET_KEY_BASE=your_secret_key_base
```

## Deployment Steps

### 1. Link to Railway Project

```bash
railway link --environment production --project desirable-integrity --service clinicpro-ash
```

### 2. Deploy Using Railway CLI

```bash
railway up --detach
```

### 3. Monitor Deployment Status

Check the Railway dashboard for build progress:
- https://railway.app/project/77c00a97-4d76-42e6-827f-e8a61a64642b/service/a6f87905-eee6-4ac8-8940-3df23d9b3ef1

### 4. Verify Deployment

Once deployed, verify the application is running:

```bash
./verify_deployment.sh https://clinicpro-ash-production.up.railway.app
```

## Troubleshooting

### Build Stuck on esbuild Download

If the build gets stuck when downloading esbuild, use the updated Dockerfile that pre-installs esbuild:

```dockerfile
# Pre-install esbuild to avoid download issues during build
RUN npm install -g esbuild@0.17.11

# Use the pre-installed version
RUN mix esbuild.install --if-missing && mix esbuild default --minify
```

### Deployment Stuck in Queued State

If the deployment is stuck in the "Queued" state:

1. Cancel the current deployment:
   ```bash
   railway down
   ```

2. Redeploy the service:
   ```bash
   railway redeploy
   ```

### No Deployments Found

If `railway logs` returns "No deployments found":

1. Ensure you're linked to the correct project and service
2. Try deploying with the `--service` flag:
   ```bash
   railway up --service clinicpro-ash --detach
   ```

## Previous Successful Deployment

The application was previously successfully deployed to:
- https://clinicpro-ash-production.up.railway.app

All authentication portals were working correctly:
- Patient Portal: /patient/request-otp
- Doctor Portal: /doctor
- Admin Portal: /admin/login
- Home Page: /

## GitHub Actions Workflow

For automated deployments, use the GitHub Actions workflow in `.github/workflows/deploy.yml` which:
1. Runs tests
2. Builds and pushes Docker image to GitHub Container Registry
3. Links to Railway project with explicit service selection
4. Deploys using Railway CLI
5. Verifies deployment using health check endpoint
