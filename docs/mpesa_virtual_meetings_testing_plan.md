# M-Pesa and Virtual Meetings Integration Testing Plan

## Overview

This document outlines the testing plan for the integration between M-Pesa payment processing and virtual meeting generation in ClinicPro. The tests focus on verifying the multi-tenant architecture, real API integrations, and fallback mechanisms.

## Prerequisites

Before running the tests, ensure the following:

1. Environment variables are set up correctly (use `source setup_test_environment.sh`)
2. Required dependencies are installed (`mix deps.get`)
3. Database is migrated (`mix ecto.migrate`)
4. Test database is prepared (`MIX_ENV=test mix ecto.reset`)

## Test Categories

### 1. M-Pesa Multi-Tenant Tests

These tests verify that each clinic can handle payments independently with its own configuration.

#### Test Cases

1. **Clinic-Specific Configuration**
   - Verify each clinic can have its own consumer key, secret, passkey, and shortcode
   - Test overriding global defaults with clinic-specific settings
   - Validate isolation between clinic configurations

2. **Transaction Isolation**
   - Ensure transactions are associated with the correct clinic_id
   - Verify clinics can only view and manage their own transactions
   - Test concurrent transactions for multiple clinics

3. **Payment Types**
   - Test STK Push payments for different clinics
   - Test C2B payments for different clinics
   - Verify different payment types (consultations, lab tests, medications)

### 2. Virtual Meetings Integration Tests

These tests verify that M-Pesa payment callbacks trigger the creation of virtual meetings.

#### Test Cases

1. **Google Meet Integration**
   - Test creating Google Meet meetings after successful M-Pesa payments
   - Verify clinic-specific Google API credentials are used
   - Test updating and deleting Google Meet meetings

2. **Zoom Integration**
   - Test creating Zoom meetings after successful M-Pesa payments
   - Verify clinic-specific Zoom API credentials are used
   - Test both OAuth 2.0 and JWT authentication methods
   - Test updating and deleting Zoom meetings

3. **Fallback Mechanism**
   - Test fallback to SimpleAdapter when Google Meet API fails
   - Test fallback to SimpleAdapter when Zoom API fails
   - Verify proper error logging during fallback

### 3. Multi-Tenant Configuration Tests

These tests verify that the virtual meeting configuration system supports multi-tenancy.

#### Test Cases

1. **Adapter Selection**
   - Test setting different adapters for different clinics
   - Verify the correct adapter is selected based on clinic context
   - Test changing adapters at runtime

2. **Credential Management**
   - Test storing and retrieving clinic-specific API credentials
   - Verify credential isolation between clinics
   - Test credential rotation and updates

3. **Base URL Configuration**
   - Test configuring different base URLs for different clinics
   - Verify meeting links use the correct base URL for each clinic

## Test Implementation

### Integration Test Module

Create a comprehensive test module at `test/clinicpro/integration/mpesa_virtual_meetings_test.exs` with the following structure:

```elixir
defmodule Clinicpro.Integration.MpesaVirtualMeetingsTest do
  use Clinicpro.DataCase
  
  # Import test helpers
  import Clinicpro.TestHelpers
  
  # Define test tags
  @moduletag :integration
  @moduletag :mpesa
  @moduletag :virtual_meetings
  
  # Setup test data
  setup do
    # Create test clinics with different configurations
    # Create test appointments
    # Set up mock M-Pesa callbacks
  end
  
  # Test cases for M-Pesa multi-tenant functionality
  describe "M-Pesa multi-tenant tests" do
    # Test cases here
  end
  
  # Test cases for virtual meetings integration
  describe "Virtual meetings integration tests" do
    # Test cases here
  end
  
  # Test cases for multi-tenant configuration
  describe "Multi-tenant configuration tests" do
    # Test cases here
  end
  
  # Helper functions for testing
end
```

### Running the Tests

To run the integration tests:

```bash
# Run all integration tests
mix test --only integration

# Run only M-Pesa tests
mix test --only mpesa

# Run only virtual meetings tests
mix test --only virtual_meetings

# Run real API tests (requires valid API credentials)
mix test --only real_api
```

## Test Data

### Test Clinics

Create the following test clinics:

1. **Clinic A**
   - Uses Google Meet adapter
   - Has its own M-Pesa credentials
   - Has its own Google API credentials

2. **Clinic B**
   - Uses Zoom adapter with OAuth 2.0
   - Has its own M-Pesa credentials
   - Has its own Zoom API credentials

3. **Clinic C**
   - Uses Zoom adapter with JWT
   - Has its own M-Pesa credentials
   - Has its own Zoom API credentials

4. **Clinic D**
   - Uses SimpleAdapter (no API credentials)
   - Has its own M-Pesa credentials

### Test Appointments

Create test appointments with:
- Different appointment types (virtual, onsite)
- Different payment statuses (pending, paid, failed)
- Different clinics
- Different doctors and patients

## Expected Results

1. Each clinic should be able to process M-Pesa payments independently
2. Successful payments should trigger the creation of virtual meetings using the clinic's configured adapter
3. Meeting links should be generated correctly and associated with the appointment
4. API failures should trigger the fallback mechanism to SimpleAdapter
5. All operations should maintain proper isolation between clinics

## Monitoring and Logging

During testing, monitor:
1. API call logs to verify correct credentials are used
2. Error logs to identify any issues with the integration
3. Database records to verify data integrity
4. Meeting link generation to ensure proper formatting

## Conclusion

This testing plan provides a comprehensive approach to verifying the M-Pesa and Virtual Meetings integration in ClinicPro's multi-tenant architecture. By following these tests, we can ensure that the integration is robust, secure, and properly isolated between clinics.
