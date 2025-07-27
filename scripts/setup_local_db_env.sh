#!/bin/bash
# Script to set up local database environment variables for ClinicPro

# Check if the script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: This script must be sourced, not executed directly."
  echo "Usage: source ./setup_local_db_env.sh [dev|test]"
  exit 1
fi

# Default to dev environment if not specified
ENV=${1:-dev}

if [[ "$ENV" == "dev" ]]; then
  echo "Setting up development database environment variables..."
  export DEV_DB_USERNAME="alex"
  export DEV_DB_PASSWORD="123"
  export DEV_DB_HOSTNAME="localhost"
  export DEV_DB_NAME="clinicpro_dev"
  echo "Development database environment variables set."
elif [[ "$ENV" == "test" ]]; then
  echo "Setting up test database environment variables..."
  export TEST_DB_USERNAME="alex"
  export TEST_DB_PASSWORD="123"
  export TEST_DB_HOSTNAME="localhost"
  export TEST_DB_NAME="clinicpro_test"
  echo "Test database environment variables set."
else
  echo "Invalid environment: $ENV. Must be 'dev' or 'test'."
  return 1
fi

echo "To use a different database configuration, modify this script or set the environment variables manually."
