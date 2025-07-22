# ClinicPro M-Pesa Integration Documentation

## Overview

This document provides a comprehensive overview of the M-Pesa integration in ClinicPro, focusing on the multi-tenant architecture, callback handling, and invoice processing.

## Architecture

The M-Pesa integration in ClinicPro follows a multi-tenant architecture where each clinic has its own payment configuration and isolated transactions. This ensures scalability, reusability, and proper isolation between clinics' payment processing.

### Key Components

1. **Main Module**: `Clinicpro.MPesa` - Entry point for all M-Pesa operations
2. **Supporting Modules**:
   - `Clinicpro.MPesa.Config` - Configuration management with multi-tenant support
   - `Clinicpro.MPesa.Auth` - Authentication handling for Safaricom Daraja API
   - `Clinicpro.MPesa.STKPush` - STK Push implementation for payment requests
   - `Clinicpro.MPesa.C2B` - C2B URL registration and payment handling
   - `Clinicpro.MPesa.Transaction` - Transaction management with clinic isolation
   - `Clinicpro.MPesa.Callback` - Callback handling for payment notifications
   - `Clinicpro.MPesa.Helpers` - Utility functions for the M-Pesa integration
3. **Invoices Module**: `Clinicpro.Invoices` - Handles invoice status updates and appointment processing
4. **Web Controllers**:
   - `ClinicproWeb.MPesaCallbackController` - Handles callbacks from M-Pesa
   - `ClinicproWeb.PaymentController` - Patient-facing payment initiation and status checking

## Multi-Tenant Design

Each clinic in ClinicPro has its own M-Pesa configuration:

1. **Clinic-Specific Configuration**:
   - Unique consumer key and secret
   - Clinic-specific passkey
   - Individual shortcodes
   - Custom callback URLs for STK Push and C2B
   - Separate validation and confirmation URLs

2. **Transaction Isolation**:
   - Each transaction is associated with a specific clinic_id
   - Clinic-specific merchant request IDs and checkout request IDs
   - Clinics can only view and manage their own transactions

3. **System Support**:
   - Multiple patients making payments to different clinics
   - Various payment types (consultations, lab tests, medications, etc.)
   - Different payment statuses (completed, pending, failed)
   - Unique reference numbers for each transaction

## Payment Flow

### STK Push Flow

1. **Initiation**:
   - Patient selects M-Pesa payment on invoice page
   - System calls `Clinicpro.MPesa.initiate_stk_push/5` with clinic_id, phone, amount, reference, and description
   - System creates a pending transaction record
   - M-Pesa sends STK Push to patient's phone

2. **Callback Handling**:
   - M-Pesa sends callback to `/api/mpesa/callbacks/stk`
   - `ClinicproWeb.MPesaCallbackController.stk_callback/2` receives the callback
   - Controller delegates to `Clinicpro.MPesa.process_stk_callback/1`
   - `Clinicpro.MPesa.Callback.process_stk/1` processes the callback and updates the transaction
   - If payment is successful, `Clinicpro.Invoices.process_completed_payment/1` is called

3. **Invoice Processing**:
   - `Clinicpro.Invoices.process_completed_payment/1` updates invoice status to "paid"
   - System appends payment details to invoice notes
   - System processes appointment based on type:
     - For virtual appointments: generates meeting link and confirms appointment
     - For onsite appointments: confirms appointment
   - System broadcasts payment events to relevant PubSub channels

### C2B Flow

1. **URL Registration**:
   - Admin registers C2B URLs for a clinic using `Clinicpro.MPesa.register_c2b_urls/1`
   - System registers validation and confirmation URLs with M-Pesa

2. **Payment Process**:
   - Patient makes payment via M-Pesa using clinic's paybill number and invoice reference
   - M-Pesa sends validation request to `/api/mpesa/callbacks/c2b/validation`
   - System validates the payment details
   - M-Pesa processes the payment and sends confirmation to `/api/mpesa/callbacks/c2b/confirmation`

3. **Callback Handling**:
   - `ClinicproWeb.MPesaCallbackController.c2b_confirmation/2` receives the callback
   - Controller delegates to `Clinicpro.MPesa.process_c2b_callback/1`
   - `Clinicpro.MPesa.Callback.process_c2b/1` processes the callback and updates the transaction
   - If payment is successful, `Clinicpro.Invoices.process_completed_payment/1` is called
   - Invoice and appointment processing proceeds as in STK Push flow

## Appointment Type Handling

The system differentiates between virtual and onsite appointments:

1. **Virtual Appointments**:
   - Require a meeting link for the virtual consultation
   - Upon successful payment, system generates a unique meeting link
   - Meeting link is stored in the appointment record
   - Appointment status is updated to "confirmed"
   - Patient can access the meeting link via the appointment details page

2. **Onsite Appointments**:
   - Do not require a meeting link
   - Upon successful payment, appointment status is updated to "confirmed"
   - Patient can view the appointment details including clinic location

## Error Handling

1. **Failed Payments**:
   - Transaction status is updated to "failed"
   - Invoice status remains "pending"
   - Appointment status remains unchanged
   - Error details are logged for troubleshooting

2. **Network Issues**:
   - System always responds with success to M-Pesa to avoid payment retries
   - Errors are logged for investigation
   - Transactions can be manually reconciled if necessary

## Broadcasting

The system broadcasts payment events to relevant PubSub channels:

1. **Clinic Channel**: `clinic:{clinic_id}`
   - Notifies clinic staff of new payments
   - Updates clinic dashboard in real-time

2. **Patient Channel**: `patient:{patient_id}`
   - Updates patient's payment status in real-time
   - Refreshes invoice status on patient's interface

3. **Appointment Channel**: `appointment:{appointment_id}`
   - Updates appointment status in real-time
   - Notifies relevant parties of appointment confirmation

## Configuration

The system uses the following environment variables:

- `VIRTUAL_MEETING_BASE_URL`: Base URL for generating virtual meeting links (default: "https://meet.clinicpro.com")

## Security Considerations

1. **Authentication**: All M-Pesa API calls use OAuth authentication with clinic-specific credentials
2. **Validation**: Transaction data is validated before processing
3. **Isolation**: Transactions and configurations are isolated by clinic
4. **Callback Verification**: Callbacks are verified against existing transactions
5. **Error Logging**: All errors are logged for audit and troubleshooting

## Testing

The system includes comprehensive tests:

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test the interaction between components
3. **Controller Tests**: Test the callback handling and HTTP responses
4. **Mock Tests**: Use mocks to simulate M-Pesa API responses

## Conclusion

The ClinicPro M-Pesa integration provides a robust, scalable, and secure payment processing solution for multiple clinics. The multi-tenant architecture ensures proper isolation between clinics, while the callback handling and invoice processing ensure that payments are correctly processed and appointments are appropriately updated based on their type.
