#!/bin/bash

# railway_deploy.sh - Phoenix-specific deployment script for Railway
# Based on Railway Phoenix guide: https://docs.railway.com/guides/phoenix

set -e  # Exit on error

echo "🚀 ClinicPro Phoenix Railway Deployment"
echo "====================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI is not installed. Please install it first."
    echo "npm i -g @railway/cli"
    exit 1
fi

# Check if we're logged in to Railway
railway whoami || {
    echo "❌ Not logged in to Railway. Please run 'railway login' first."
    exit 1
}

echo "✅ Railway CLI is available and logged in"

# Link to the correct project and service
echo "🔗 Linking to Railway project and service..."
railway link --environment production --project desirable-integrity --service clinicpro-ash

# Ask user which deployment method to use
echo ""
echo "📋 Select deployment method:"
echo "1) Docker-based deployment (recommended - most reliable)"
echo "2) Phoenix source deployment (may get stuck on compilation)"
echo "3) GitHub-based deployment (requires manual setup)"
read -p "Enter your choice (1-3): " deployment_choice

case $deployment_choice in
    1)
        echo "🚀 Starting Docker-based deployment..."

        # Check if Docker is installed
        if ! command -v docker &> /dev/null; then
            echo "❌ Docker is not installed. Please install it first."
            exit 1
        fi

        # Build Docker image
        echo "🔨 Building Docker image..."
        docker build -t ghcr.io/shelfwise-llc/clinicpro-ash:latest .
        
        # Login to GitHub Container Registry
        echo "🔑 Logging in to GitHub Container Registry..."
        read -p "Enter your GitHub token: " github_token
        echo $github_token | docker login ghcr.io -u shelfwise-llc --password-stdin
        
        # Push Docker image
        echo "📤 Pushing Docker image to GitHub Container Registry..."
        docker push ghcr.io/shelfwise-llc/clinicpro-ash:latest
        
        # Set required Phoenix environment variables for Docker deployment
        echo "📝 Setting Phoenix-specific environment variables..."
        SECRET_KEY=$(mix phx.gen.secret)
        railway variables --set "SECRET_KEY_BASE=$SECRET_KEY" \
                         --set "LANG=en_US.UTF-8" \
                         --set "LC_CTYPE=en_US.UTF-8" \
                         --set "ECTO_IPV6=true" \
                         --set "PHX_SERVER=true" \
                         --set "PHX_HOST=clinicpro-ash-production.up.railway.app" \
                         --set "PORT=4000"
        
        # Deploy using Railway variables
        echo "🚂 Deploying to Railway using Docker image..."
        railway variables --set "RAILWAY_DOCKERFILE_PATH=Dockerfile" \
                         --set "RAILWAY_DOCKERFILE_IMAGE=ghcr.io/shelfwise-llc/clinicpro-ash:latest"
        railway up --detach
        ;;
    2)
        echo "🚀 Starting Phoenix source deployment..."
        echo "⚠️  Warning: This may get stuck during compilation on Railway's build environment"
        
        # Set required Phoenix environment variables
        echo "📝 Setting Phoenix-specific environment variables..."
        
        # Generate a new secret key if needed
        echo "Generating new SECRET_KEY_BASE..."
        SECRET_KEY=$(mix phx.gen.secret)
        
        # Set all required Phoenix environment variables
        railway variables --set "SECRET_KEY_BASE=$SECRET_KEY" \
                         --set "LANG=en_US.UTF-8" \
                         --set "LC_CTYPE=en_US.UTF-8" \
                         --set "ECTO_IPV6=true" \
                         --set "PHX_SERVER=true" \
                         --set "PHX_HOST=clinicpro-ash-production.up.railway.app" \
                         --set "PORT=4000"
        
        # Deploy the application
        echo "🚀 Deploying Phoenix application to Railway..."
        railway up --detach
        ;;
    3)
        echo "🚀 Starting GitHub-based deployment..."

        # Set up GitHub repository as the deployment source
        echo "🔗 Setting up GitHub repository as deployment source..."
        echo "Note: This method requires manual configuration in the Railway dashboard."
        echo "Please go to https://railway.app/project/77c00a97-4d76-42e6-827f-e8a61a64642b/service/a6f87905-eee6-4ac8-8940-3df23d9b3ef1"
        echo "and connect your GitHub repository using the Railway dashboard."
        
        # Set required Phoenix environment variables
        echo "📝 Setting Phoenix-specific environment variables..."
        railway variables --set "LANG=en_US.UTF-8" \
                         --set "LC_CTYPE=en_US.UTF-8" \
                         --set "ECTO_IPV6=true"
        
        # Trigger deployment
        echo "🚂 Triggering deployment from GitHub repository..."
        railway up --detach
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "✅ Deployment initiated!"
echo "⏳ Waiting for deployment to complete (this may take a few minutes)..."
sleep 30

# Check deployment status
echo "🔍 Checking deployment status..."
railway status

# Run database migrations in the correct order
echo "📝 Running database migrations..."
echo "First ensuring all tables are created..."
railway run -- mix ecto.create --quiet || echo "Database already exists"

# Run migrations with proper error handling
echo "Running migrations..."
railway run -- mix ecto.migrate || {
    echo "\n\u26A0\uFE0F Migration failed. Attempting to fix common issues..."
    
    # Check if we need to create doctors table first
    echo "Checking if doctors table needs to be created first..."
    railway run -- mix run -e "IO.puts(\"Checking database structure...\"); Clinicpro.Repo.query(\"CREATE TABLE IF NOT EXISTS doctors (id uuid PRIMARY KEY, name text, email text, clinic_id uuid REFERENCES clinics(id))\")"
    
    # Try migrations again
    echo "Retrying migrations..."
    railway run -- mix ecto.migrate || echo "Migration still failed. You may need to manually fix the database schema."
}

# Verify the application is running
echo "🔍 Checking if application is accessible..."
HEALTH_STATUS=$(curl -s -w "%{http_code}" -o /tmp/health_response.txt https://clinicpro-ash-production.up.railway.app/health)

echo ""
if [ "$HEALTH_STATUS" == "200" ]; then
    echo "💚 Health check passed! Application is running correctly."
    cat /tmp/health_response.txt
    echo ""
    
    # Check authentication portals
    echo "🔑 Verifying authentication portals..."
    
    # Check patient portal
    PATIENT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://clinicpro-ash-production.up.railway.app/patient/request-otp)
    if [ "$PATIENT_STATUS" == "200" ]; then
        echo "💚 Patient portal is accessible."
    else
        echo "💔 Patient portal returned status $PATIENT_STATUS"
    fi
    
    # Check doctor portal
    DOCTOR_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://clinicpro-ash-production.up.railway.app/doctor)
    if [ "$DOCTOR_STATUS" == "200" ]; then
        echo "💚 Doctor portal is accessible."
    else
        echo "💔 Doctor portal returned status $DOCTOR_STATUS"
    fi
    
    # Check admin portal
    ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://clinicpro-ash-production.up.railway.app/admin/login)
    if [ "$ADMIN_STATUS" == "200" ]; then
        echo "💚 Admin portal is accessible."
    else
        echo "💔 Admin portal returned status $ADMIN_STATUS"
    fi
else
    echo "💔 Health check failed with status $HEALTH_STATUS. Application may not be running correctly."
    echo "This could be due to:"
    echo "  - Deployment still in progress"
    echo "  - Database connection issues"
    echo "  - Application startup errors"
    echo ""
    echo "Check Railway logs for more information:"
    railway logs
fi

echo ""
echo "🌐 Your application should be available at: https://clinicpro-ash-production.up.railway.app"
echo "📋 To verify the deployment, run: ./verify_deployment.sh https://clinicpro-ash-production.up.railway.app"

# Open the application in a browser
echo "👀 Opening application in browser..."
echo "Visit: https://clinicpro-ash-production.up.railway.app"
