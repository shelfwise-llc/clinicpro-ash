#!/bin/bash

# Exit on any error
set -e

echo "Starting deployment process..."

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "Railway CLI not found. Installing..."
    curl -fsSL https://railway.app/install.sh | sh
fi

# Link to the Railway project
echo "Linking Railway project..."
railway link --project desirable-integrity --environment production --service clinicpro-ash

# Set proper environment variables
echo "Setting environment variables..."
SECRET_KEY_BASE=$(mix phx.gen.secret)
railway variables --set "SECRET_KEY_BASE=$SECRET_KEY_BASE"
railway variables --set "DATABASE_URL=ecto://postgres:XkggcTaQwXrloywONDieBlwLeGSGEhDS@postgres-p8mu.railway.internal:5432/railway"
railway variables --set "PHX_SERVER=true"
railway variables --set "PHX_HOST=clinicpro-ash-production.up.railway.app"
railway variables --set "PORT=4000"
railway variables --set "ECTO_IPV6=true"
railway variables --set "LANG=en_US.UTF-8"
railway variables --set "LC_CTYPE=en_US.UTF-8"

# Deploy to Railway
echo "Deploying to Railway..."
railway up

echo "Deployment completed!"
