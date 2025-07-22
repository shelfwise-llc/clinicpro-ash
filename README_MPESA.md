# ClinicPro M-Pesa Integration

## Overview

This README provides a quick reference guide for the M-Pesa integration in ClinicPro, focusing on the multi-tenant architecture, payment flows, and callback handling.

## Features

- **Multi-tenant architecture**: Each clinic has its own M-Pesa configuration and isolated transactions
- **Payment methods**: Supports both STK Push and C2B payment methods
- **Appointment handling**: Differentiates between virtual and onsite appointments
- **Real-time updates**: Broadcasts payment events to relevant PubSub channels
- **Comprehensive error handling**: Handles edge cases and network issues gracefully

## Directory Structure

```
lib/clinicpro/
├── mpesa/
│   ├── mpesa.ex              # Main entry point for M-Pesa operations
│   ├── auth.ex               # Authentication handling for Safaricom Daraja API
│   ├── config.ex             # Configuration management with multi-tenant support
│   ├── stk_push.ex           # STK Push implementation for payment requests
│   ├── c2b.ex                # C2B URL registration and payment handling
│   ├── transaction.ex        # Transaction management with clinic isolation
│   ├── callback.ex           # Callback handling for payment notifications
│   └── helpers.ex            # Utility functions for the M-Pesa integration
├── invoices.ex               # Invoice status updates and appointment processing
└── admin_bypass/
    ├── appointment.ex        # Appointment schema and CRUD operations
    └── invoice.ex            # Invoice schema and CRUD operations

lib/clinicpro_web/
├── controllers/
│   ├── mpesa_callback_controller.ex  # Handles callbacks from M-Pesa
│   └── payment_controller.ex         # Patient-facing payment initiation
└── router.ex                         # Defines routes for M-Pesa callbacks
```

## Setup Requirements

1. **M-Pesa API Credentials**:
   - Consumer Key and Secret for each clinic
   - Passkey for each clinic
   - Shortcode for each clinic

2. **Environment Variables**:
   - `VIRTUAL_MEETING_BASE_URL`: Base URL for generating virtual meeting links (default: "https://meet.clinicpro.com")

3. **Callback URLs**:
   - STK Push: `https://your-domain.com/api/mpesa/callbacks/stk`
   - C2B Validation: `https://your-domain.com/api/mpesa/callbacks/c2b/validation`
   - C2B Confirmation: `https://your-domain.com/api/mpesa/callbacks/c2b/confirmation`

## Usage Examples

### Initiating STK Push Payment

```elixir
# Get invoice details
invoice = Clinicpro.AdminBypass.Invoice.get_invoice!(invoice_id)

# Initiate STK Push
{:ok, transaction} = Clinicpro.MPesa.initiate_stk_push(
  invoice.clinic_id,
  patient_phone,
  invoice.amount,
  invoice.payment_reference,
  invoice.description
)
```

### Registering C2B URLs for a Clinic

```elixir
# Register C2B URLs for a clinic
{:ok, response} = Clinicpro.MPesa.register_c2b_urls(clinic_id)
```

### Checking Transaction Status

```elixir
# Check status of an STK Push transaction
{:ok, response} = Clinicpro.MPesa.query_stk_status(checkout_request_id, clinic_id)
```

## Callback Handling

The system automatically handles callbacks from M-Pesa:

1. **STK Push Callback**:
   - Updates transaction status
   - Updates invoice status if payment is successful
   - Processes appointment based on type (virtual or onsite)
   - Broadcasts payment events

2. **C2B Callbacks**:
   - Validates payment details
   - Updates transaction status
   - Updates invoice status if payment is successful
   - Processes appointment based on type
   - Broadcasts payment events

## Testing

Run the tests with:

```bash
mix test test/clinicpro/mpesa
mix test test/clinicpro/invoices_test.exs
mix test test/clinicpro_web/controllers/mpesa_callback_controller_test.exs
```

## Documentation

For more detailed documentation, see:

- [M-Pesa Integration Documentation](docs/mpesa_integration.md)
- [Safaricom Daraja API Documentation](https://developer.safaricom.co.ke/docs)

## Troubleshooting

Common issues:

1. **Transaction not found**: Ensure the payment reference matches an existing invoice
2. **Configuration not found**: Verify that the clinic has M-Pesa credentials configured
3. **Callback not processing**: Check that the callback URLs are correctly registered with Safaricom

## Contributing

When contributing to the M-Pesa integration:

1. Follow the multi-tenant architecture principles
2. Ensure proper error handling and logging
3. Write tests for new functionality
4. Update documentation as needed

## License

This project is licensed under the terms specified in the main ClinicPro license.
