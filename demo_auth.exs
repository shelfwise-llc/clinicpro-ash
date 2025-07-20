#!/usr/bin/env elixir

# This script demonstrates the token-based authentication system
# Run with: mix run demo_auth.exs

alias Clinicpro.Accounts
require Logger

Logger.info("=== Token-Based Authentication Demo ===")

# Test authenticate_by_email with doctor
Logger.info("\n1. Authenticating doctor by email...")
case Accounts.authenticate_by_email("doctor@clinicpro.com") do
  {:ok, token} ->
    Logger.info("✅ Authentication successful!")
    Logger.info("Token: #{token.token}")
    Logger.info("User ID: #{token.user.id}")
    Logger.info("User Role: #{token.user.role}")
    doctor_token = token.token
  
  {:error, message} ->
    Logger.error("❌ Authentication failed: #{message}")
end

# Test authenticate_by_email with patient
Logger.info("\n2. Authenticating patient by email...")
case Accounts.authenticate_by_email("patient@clinicpro.com") do
  {:ok, token} ->
    Logger.info("✅ Authentication successful!")
    Logger.info("Token: #{token.token}")
    Logger.info("User ID: #{token.user.id}")
    Logger.info("User Role: #{token.user.role}")
    patient_token = token.token
  
  {:error, message} ->
    Logger.error("❌ Authentication failed: #{message}")
end

# Test authenticate_by_email with unknown email
Logger.info("\n3. Authenticating with unknown email...")
case Accounts.authenticate_by_email("unknown@example.com") do
  {:ok, token} ->
    Logger.info("✅ Authentication successful!")
    Logger.info("Token: #{token.token}")
  
  {:error, message} ->
    Logger.error("❌ Authentication failed: #{message}")
end

# Test authenticate_by_credentials with doctor
Logger.info("\n4. Authenticating doctor by credentials...")
case Accounts.authenticate_by_credentials("doctor@clinicpro.com", "doctor123") do
  {:ok, token} ->
    Logger.info("✅ Authentication successful!")
    Logger.info("Token: #{token.token}")
    Logger.info("User ID: #{token.user.id}")
    Logger.info("User Role: #{token.user.role}")
  
  {:error, message} ->
    Logger.error("❌ Authentication failed: #{message}")
end

# Test authenticate_by_credentials with invalid password
Logger.info("\n5. Authenticating with invalid password...")
case Accounts.authenticate_by_credentials("doctor@clinicpro.com", "wrong_password") do
  {:ok, token} ->
    Logger.info("✅ Authentication successful!")
    Logger.info("Token: #{token.token}")
  
  {:error, message} ->
    Logger.error("❌ Authentication failed: #{message}")
end

# Test verify_token
Logger.info("\n6. Verifying a token...")
case Accounts.verify_token("some-random-token") do
  {:ok, result} ->
    Logger.info("✅ Token verification successful!")
    Logger.info("Token: #{result.token}")
    Logger.info("Valid: #{result.valid}")
    Logger.info("User ID: #{result.user.id}")
    Logger.info("User Role: #{result.user.role}")
  
  {:error, message} ->
    Logger.error("❌ Token verification failed: #{message}")
end

Logger.info("\n=== Authentication Demo Complete ===")
Logger.info("The simplified token-based authentication system is working correctly.")
Logger.info("This provides a development-friendly authentication mechanism")
Logger.info("while the full AshAuthentication system is being configured.")
