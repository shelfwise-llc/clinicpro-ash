# ClinicPro Railway Environment Variables Setup

This guide explains how to set up the required environment variables for your ClinicPro application on Railway.

## Required Environment Variables

### Core Phoenix Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Used for cryptographic signing in Phoenix | `openssl rand -base64 64` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:password@localhost/clinicpro_prod` |
| `PHX_HOST` | Host name for production | `clinicpro.up.railway.app` |
| `PORT` | Port for the application (set by Railway) | `4000` |

### Paystack Integration Variables

Based on the multi-tenant Paystack integration in ClinicPro, you'll need:

| Variable | Description |
|----------|-------------|
| `PAYSTACK_DEFAULT_PUBLIC_KEY` | Default Paystack public key |
| `PAYSTACK_DEFAULT_SECRET_KEY` | Default Paystack secret key |
| `PAYSTACK_DEFAULT_MERCHANT_EMAIL` | Default merchant email |
| `PAYSTACK_DEFAULT_CALLBACK_URL` | Default callback URL for payment verification |

### Paystack Integration Variables

| Variable | Description |
|----------|-------------|
| `PAYSTACK_SECRET_KEY` | Default Paystack secret key |
| `PAYSTACK_PUBLIC_KEY` | Default Paystack public key |

### Authentication Variables

| Variable | Description |
|----------|-------------|
| `OTP_VALIDITY_PERIOD` | Period in seconds for OTP validity |
| `MAGIC_LINK_BASE_URL` | Base URL for magic links |

## Setting Environment Variables on Railway

### Method 1: Using the Railway Dashboard

1. Go to your project on Railway: https://railway.app/project/77c00a97-4d76-42e6-827f-e8a61a64642b
2. Click on your service
3. Go to the "Variables" tab
4. Add each environment variable and its value
5. Click "Save" to apply the changes

### Method 2: Using the Railway CLI

```bash
# Set individual variables
railway variables set SECRET_KEY_BASE=your_secret_key_base
railway variables set DATABASE_URL=your_database_url
railway variables set PHX_HOST=your_app_domain.up.railway.app

# Set multiple variables at once
railway variables set \
  MPESA_DEFAULT_CONSUMER_KEY=your_consumer_key \
  MPESA_DEFAULT_CONSUMER_SECRET=your_consumer_secret \
  MPESA_DEFAULT_PASSKEY=your_passkey \
  MPESA_DEFAULT_SHORTCODE=your_shortcode
```

### Method 3: Using Environment Variables File

1. Create a `.env` file with your variables:

```
SECRET_KEY_BASE=your_secret_key_base
DATABASE_URL=your_database_url
PHX_HOST=your_app_domain.up.railway.app
# Add other variables here
```

2. Import the file using Railway CLI:

```bash
railway variables from .env
```

## Generating a Secret Key Base

For the `SECRET_KEY_BASE` variable, you can generate a secure value using:

```bash
mix phx.gen.secret
```

## Database Configuration

Railway automatically provisions a PostgreSQL database when you add it as a service. You can link it to your application:

1. Add a PostgreSQL service to your project
2. Railway will automatically inject the `DATABASE_URL` variable
3. Link the database to your application service

## Testing Environment Variables

To verify your environment variables are set correctly:

```bash
railway run mix run -e "IO.puts(System.get_env(\"SECRET_KEY_BASE\"))"
```

