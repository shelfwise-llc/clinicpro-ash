# ClinicPro Database Configuration Guide

This document explains how to configure database credentials for different environments in the ClinicPro application.

## Environment-Specific Database Configuration

ClinicPro supports different database configurations for development, testing, and production environments:

### Local Development

For local development, you can set the following environment variables:

- `DEV_DB_USERNAME` - Database username (default: "alex")
- `DEV_DB_PASSWORD` - Database password (default: "123")
- `DEV_DB_HOSTNAME` - Database host (default: "localhost")
- `DEV_DB_NAME` - Database name (default: "clinicpro_dev")

### Testing

For the test environment, you can set:

- `TEST_DB_USERNAME` - Test database username (default: "alex")
- `TEST_DB_PASSWORD` - Test database password (default: "123")
- `TEST_DB_HOSTNAME` - Test database host (default: "localhost")
- `TEST_DB_NAME` - Test database name (default: "clinicpro_test")

The test database name will have an optional partition suffix for CI environments.

### Production (Railway)

For production deployment on Railway, the application uses:

- `DATABASE_URL` - Full database connection URL (required)
- `POOL_SIZE` - Connection pool size (default: "10")

## Using the Helper Script

We've provided a helper script to easily set up your local environment variables:

```bash
# For development environment
source ./scripts/setup_local_db_env.sh dev

# For test environment
source ./scripts/setup_local_db_env.sh test
```

## Manual Configuration

You can also set these environment variables manually:

```bash
# Development
export DEV_DB_USERNAME="your_username"
export DEV_DB_PASSWORD="your_password"
export DEV_DB_HOSTNAME="your_host"
export DEV_DB_NAME="your_database"

# Testing
export TEST_DB_USERNAME="your_test_username"
export TEST_DB_PASSWORD="your_test_password"
export TEST_DB_HOSTNAME="your_test_host"
export TEST_DB_NAME="your_test_database"
```

## Railway Deployment

When deploying to Railway, make sure the `DATABASE_URL` environment variable is correctly set in your Railway project settings. The application will automatically use this connection URL when available.

If you're using the GitHub Actions CI/CD pipeline, ensure that the `DATABASE_URL` secret is set in your GitHub repository secrets.

## Troubleshooting

If you encounter database connection issues:

1. Verify that PostgreSQL is running and accessible
2. Check that your environment variables match your PostgreSQL configuration
3. For test failures, ensure the test database exists and is accessible
4. For Railway deployments, verify the `DATABASE_URL` is correctly formatted

For more information on Railway deployment, refer to the Railway deployment documentation.
