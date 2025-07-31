#!/bin/bash

# local_deploy.sh - Script for local development with Kamal
# This script helps test the deployment process locally before pushing to production

set -e  # Exit on error

echo "🚀 ClinicPro Local Development with Kamal"
echo "========================================"

# Check if Kamal is installed
if ! command -v kamal &> /dev/null; then
    echo "❌ Kamal is not installed. Please install it first:"
    echo "gem install kamal"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Create local development environment file if it doesn't exist
if [ ! -f .env.development ]; then
    echo "Creating .env.development file..."
    cat > .env.development << EOF
# Local development environment variables
MIX_ENV=dev
PHX_SERVER=true
PORT=4000
PHX_HOST=localhost
SECRET_KEY_BASE=$(mix phx.gen.secret)
DATABASE_URL=postgres://postgres:postgres@localhost:5432/clinicpro_dev
POOL_SIZE=10
EOF
    echo "✅ Created .env.development file with default values"
fi

# Create local Kamal configuration if it doesn't exist
if [ ! -f config/deploy.local.yml ]; then
    echo "Creating local Kamal deployment configuration..."
    cat > config/deploy.local.yml << EOF
# Local development configuration for Kamal
service: clinicpro-local
image: clinicpro-local

servers:
  web:
    - localhost

registry:
  server: local
  username: local
  password: local

builder:
  multiarch: false
  args:
    MIX_ENV: dev

env:
  clear:
    MIX_ENV: dev
    PHX_SERVER: "true"
    PORT: 4000
    PHX_HOST: localhost
  secret:
    - DATABASE_URL
    - SECRET_KEY_BASE

accessories:
  postgres:
    image: postgres:15
    port: 5432
    env:
      clear:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: clinicpro_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data

boot:
  limit: 1
  wait: 5
EOF
    echo "✅ Created local Kamal deployment configuration"
fi

# Build and deploy locally
echo "🔨 Building and deploying locally with Kamal..."
export KAMAL_REGISTRY_PASSWORD=local
export DATABASE_URL=$(grep DATABASE_URL .env.development | cut -d '=' -f2-)
export SECRET_KEY_BASE=$(grep SECRET_KEY_BASE .env.development | cut -d '=' -f2-)

# Setup and deploy
kamal setup --destination local
kamal deploy --destination local

echo "✅ Local deployment complete!"
echo "📋 You can access the application at http://localhost:4000"
