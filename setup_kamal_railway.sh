#!/bin/bash

# Setup script for Kamal deployment to Railway
# This script helps configure the necessary environment variables

echo "🚀 ClinicPro Kamal + Railway Setup"
echo "=================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Please install it first:"
    echo "   npm install -g @railway/cli"
    exit 1
fi

# Check if user is logged in to Railway
if ! railway whoami &> /dev/null; then
    echo "🔐 Please log in to Railway first:"
    echo "   railway login"
    exit 1
fi

echo "✅ Railway CLI is ready"

# Generate SECRET_KEY_BASE if not exists
if [ -z "$SECRET_KEY_BASE" ]; then
    echo "🔑 Generating SECRET_KEY_BASE..."
    SECRET_KEY_BASE=$(mix phx.gen.secret)
    echo "Generated SECRET_KEY_BASE: $SECRET_KEY_BASE"
    echo "Please set this in your Railway environment variables:"
    echo "   railway variables set SECRET_KEY_BASE=\"$SECRET_KEY_BASE\""
fi

echo ""
echo "📋 Required Railway Environment Variables:"
echo "=========================================="
echo "1. DATABASE_URL - PostgreSQL connection string"
echo "2. SECRET_KEY_BASE - Phoenix secret key"
echo "3. PAYSTACK_SECRET_KEY - Paystack secret key"
echo "4. PAYSTACK_PUBLIC_KEY - Paystack public key"
echo ""
echo "📋 Required GitHub Secrets:"
echo "=========================="
echo "1. DATABASE_URL - Same as Railway"
echo "2. SECRET_KEY_BASE - Same as Railway"
echo "3. PAYSTACK_SECRET_KEY - Same as Railway"
echo "4. PAYSTACK_PUBLIC_KEY - Same as Railway"
echo "5. RAILWAY_SERVER_HOST - Your Railway app's internal host"
echo "6. RAILWAY_PUBLIC_DOMAIN - Your Railway app's public domain"
echo ""
echo "🔧 Next Steps:"
echo "============="
echo "1. Add a PostgreSQL database to your Railway project"
echo "2. Set the environment variables in Railway"
echo "3. Set the secrets in GitHub repository settings"
echo "4. Push to main branch to trigger deployment"
echo ""
echo "💡 To deploy manually:"
echo "   kamal deploy"
echo ""
echo "💡 To check deployment status:"
echo "   kamal app logs"
echo ""
echo "💡 To rollback if needed:"
echo "   kamal app rollback [VERSION]"
