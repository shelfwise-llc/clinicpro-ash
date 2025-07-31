# ClinicPro Deployment Guide

This document outlines the deployment process for ClinicPro, a multi-tenant medical application with portals for doctors, patients, and admins.

## Deployment Pipeline

The ClinicPro deployment pipeline consists of the following steps:

1. **Local Development with Kamal**
   - Test the application in a production-like environment
   - Build and verify Docker images locally
   - Ensure all environment variables are properly configured

2. **GitHub Actions CI/CD**
   - Run tests, formatting checks, and compilation
   - Build Docker images and push to GitHub Container Registry
   - Deploy to Railway using Kamal

3. **Railway Production Deployment**
   - Host the application with proper environment variables
   - Ensure database connection and proper server startup
   - Verify deployment with health checks

## Required Environment Variables

The following environment variables are required for proper deployment:

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:password@host:port/database` |
| `SECRET_KEY_BASE` | Phoenix secret key for encryption | Generated with `mix phx.gen.secret` |
| `PHX_SERVER` | Flag to start Phoenix server | `true` |
| `PORT` | Listening port | `4000` |
| `PHX_HOST` | Railway public domain | `clinicpro-ash-production.up.railway.app` |
| `PAYSTACK_SECRET_KEY` | Paystack API secret key | `sk_test_...` |
| `PAYSTACK_PUBLIC_KEY` | Paystack API public key | `pk_test_...` |

## Deployment Tools

### Kamal

[Kamal](https://kamal-deploy.org/) is used for both local development testing and production deployment. It provides a reliable way to build, push, and deploy Docker images.

#### Local Development with Kamal

```bash
# Run the local development script
./local_deploy.sh
```

#### Production Deployment with Kamal

```bash
# Deploy to production
kamal deploy
```

### Railway

[Railway](https://railway.app/) is the hosting platform for ClinicPro. It provides PostgreSQL database and hosting for the application.

#### Railway CLI Commands

```bash
# List environment variables
railway variables

# Set environment variables
railway variables --set KEY=VALUE

# Deploy the application
railway up

# View logs
railway logs
```

## Troubleshooting

### 404 Not Found Error

If you encounter a 404 "Not Found" error after deployment, check the following:

1. **Environment Variables**: Ensure the following environment variables are set correctly:
   - `PHX_SERVER=true`
   - `PORT=4000`
   - `PHX_HOST=clinicpro-ash-production.up.railway.app`

2. **Application Startup**: Check the logs to ensure the Phoenix server is starting correctly:
   ```bash
   railway logs
   ```

3. **Health Check**: Use the health check endpoint to verify the application is running:
   ```bash
   curl https://clinicpro-ash-production.up.railway.app/health
   ```

### Database Connection Issues

If the application fails to connect to the database, check the following:

1. **DATABASE_URL**: Ensure the `DATABASE_URL` environment variable is set correctly.
2. **Database Migrations**: Run migrations if needed:
   ```bash
   railway run mix ecto.migrate
   ```

### Deployment Verification

Use the verification script to check if the deployment is working correctly:

```bash
./verify_deployment.sh https://clinicpro-ash-production.up.railway.app
```

## Authentication Portals

ClinicPro has three authentication portals:

1. **Patient Portal**: `/patient/request-otp`
   - OTP-based authentication with rate limiting

2. **Doctor Portal**: `/doctor`
   - Email/password authentication with password hashing

3. **Admin Portal**: `/admin/login`
   - Admin authentication with secure session management

## Security Considerations

- All passwords are hashed using SHA-256 (consider upgrading to Argon2 or Bcrypt)
- Rate limiting is implemented for login attempts (5 attempts per hour)
- Session tracking includes IP address and user agent logging
- Comprehensive audit logging for security events

## Monitoring and Maintenance

- Regularly check the application logs for errors
- Monitor database performance and connection issues
- Keep dependencies updated to address security vulnerabilities
- Perform regular backups of the database
