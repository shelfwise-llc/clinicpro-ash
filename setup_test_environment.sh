#!/bin/bash

# Script to set up environment variables for testing Paystack and Virtual Meetings integration

echo "Setting up environment variables for testing..."

# Paystack API credentials (replace with actual test credentials)
export PAYSTACK_PUBLIC_KEY="pk_test_your_public_key"
export PAYSTACK_SECRET_KEY="sk_test_your_secret_key"
export PAYSTACK_WEBHOOK_URL="https://yourdomain.com/webhooks/paystack"

# Google Meet API credentials
# This should be the contents of the service account JSON file
export GOOGLE_API_CREDENTIALS_JSON='{
  "type": "service_account",
  "project_id": "your_project_id",
  "private_key_id": "your_private_key_id",
  "private_key": "your_private_key",
  "client_email": "your_client_email",
  "client_id": "your_client_id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "your_cert_url"
}'
export GOOGLE_CALENDAR_ID="primary"

# Zoom API credentials
# OAuth 2.0 Server-to-Server
export ZOOM_CLIENT_ID="your_zoom_client_id"
export ZOOM_CLIENT_SECRET="your_zoom_client_secret"
export ZOOM_ACCOUNT_ID="your_zoom_account_id"

# JWT (legacy)
export ZOOM_API_KEY="your_zoom_api_key"
export ZOOM_API_SECRET="your_zoom_api_secret"

echo "Environment variables set up successfully!"
echo "To use these variables in your current shell, run:"
echo "source setup_test_environment.sh"
