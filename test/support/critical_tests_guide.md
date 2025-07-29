# ClinicPro Critical Tests Guide

This guide explains how to tag tests as "critical" for deployment validation.

## What are Critical Tests?

Critical tests verify essential functionality that must work for a successful deployment:

- Authentication flows
- Payment processing (Paystack)
- Multi-tenant clinic isolation
- Core appointment scheduling
- Patient data security

## How to Tag a Test as Critical

Add the `@tag :critical` attribute to any test that should be run during deployment:

```elixir
@tag :critical
test "patient can authenticate with OTP", %{conn: conn} do
  # Test implementation
end
```

For entire modules that contain only critical tests:

```elixir
defmodule Clinicpro.CriticalAuthTest do
  use ClinicproWeb.ConnCase
  
  @moduletag :critical
  
  # All tests in this module will be tagged as critical
end
```

## Example Critical Tests

Here are examples of tests that should be tagged as critical:

1. **Authentication**
   - OTP rate limiting functionality
   - Magic link authentication
   - Multi-tenant authentication isolation

2. **Payment Processing**
   - Paystack payment processing
   - Transaction isolation between clinics

3. **Core Functionality**
   - Appointment scheduling
   - Prescription management
   - Invoice generation

## Running Only Critical Tests

To run only critical tests:

```bash
mix test --only critical
```

This command is used in the deployment script to validate essential functionality before deployment.
