# ClinicPro M-Pesa Integration with Virtual Meetings

This document provides a comprehensive overview of the M-Pesa integration with virtual meeting capabilities in ClinicPro, designed for multi-tenant healthcare clinics in Kenya.

## Architecture Overview

The integration follows a multi-tenant architecture where each clinic has its own isolated payment processing and virtual meeting configuration. The system is designed to be:

1. **Scalable**: Handles varying transaction volumes from low to thousands
2. **Reusable**: Core components can be used in other applications
3. **Secure**: Proper isolation between clinics and secure handling of payment data
4. **Extensible**: Supports multiple payment methods and virtual meeting providers

### Key Components

#### M-Pesa Integration

- **Clinicpro.MPesa**: Main module for M-Pesa integration
- **Clinicpro.MPesa.Config**: Multi-tenant configuration management
- **Clinicpro.MPesa.Auth**: Authentication with Safaricom Daraja API
- **Clinicpro.MPesa.STKPush**: STK Push implementation
- **Clinicpro.MPesa.C2B**: C2B URL registration and payment handling
- **Clinicpro.MPesa.Transaction**: Transaction management with clinic isolation
- **Clinicpro.MPesa.Callback**: Callback handling for payment notifications
- **Clinicpro.MPesa.Simulator**: Test utilities for simulating callbacks

#### Virtual Meeting Integration

- **Clinicpro.VirtualMeetings.Adapter**: Behaviour defining virtual meeting provider interface
- **Clinicpro.VirtualMeetings.Config**: Configuration management for meeting providers
- **Clinicpro.VirtualMeetings.SimpleAdapter**: Simple adapter generating meeting URLs without external APIs
- **Clinicpro.VirtualMeetings.GoogleMeetAdapter**: Google Meet integration via Google Calendar API
- **Clinicpro.VirtualMeetings.ZoomAdapter**: Zoom integration via Zoom API

#### Integration Points

- **Clinicpro.Invoices**: Handles invoice status updates and appointment processing upon payment completion
- **ClinicproWeb.MPesaCallbackController**: Receives and processes M-Pesa callbacks

## Multi-tenant Architecture

### M-Pesa Multi-tenant Design

Each clinic has its own isolated M-Pesa configuration:

- **Unique credentials**: Consumer key, secret, passkey
- **Individual shortcodes**: Each clinic has its own M-Pesa shortcode
- **Custom callback URLs**: Clinic-specific callback endpoints
- **Isolated transactions**: Transactions are associated with specific clinics

### Virtual Meeting Multi-tenant Design

Each clinic can have its own virtual meeting configuration:

- **Provider selection**: Clinics can use different meeting providers (Simple, Google Meet, Zoom)
- **Custom credentials**: Each clinic can have its own API credentials
- **Base URL configuration**: Customizable meeting URL base for branding purposes

## Payment Flows

### STK Push Flow

1. Patient initiates payment from the ClinicPro app
2. System sends STK Push request to M-Pesa with clinic-specific credentials
3. Patient receives payment prompt on their phone
4. Patient enters M-Pesa PIN to authorize payment
5. M-Pesa processes payment and sends callback to ClinicPro
6. ClinicPro processes callback asynchronously:
   - Updates invoice status to "paid"
   - For virtual appointments: generates meeting link using configured adapter
   - For onsite appointments: confirms appointment without meeting link
7. Patient receives confirmation and meeting link (if virtual)

### C2B Flow

1. Patient makes payment directly via M-Pesa to clinic's paybill number
2. Patient enters invoice reference as account number
3. M-Pesa processes payment and sends callback to ClinicPro
4. ClinicPro processes callback asynchronously (same as STK Push)

## Virtual Meeting Integration

### Meeting Provider Selection

The system supports multiple virtual meeting providers through an adapter pattern:

- **SimpleAdapter**: Generates predictable meeting URLs without external API calls (default)
- **GoogleMeetAdapter**: Creates meetings via Google Calendar API
- **ZoomAdapter**: Creates meetings via Zoom API

### Configuration

```elixir
# In config/config.exs, config/dev.exs, etc.
config :clinicpro,
  virtual_meeting_adapter: Clinicpro.VirtualMeetings.SimpleAdapter,
  virtual_meeting_base_url: "https://meet.clinicpro.com"

# For Google Meet integration
config :clinicpro,
  google_api_credentials: %{
    # Google API credentials here
  }

# For Zoom integration
config :clinicpro,
  zoom_api_credentials: %{
    # Zoom API credentials here
  }
```

### Runtime Configuration

```elixir
# Set the adapter to use
Clinicpro.VirtualMeetings.Config.set_adapter(Clinicpro.VirtualMeetings.GoogleMeetAdapter)

# Set adapter for a specific clinic
Clinicpro.VirtualMeetings.Config.set_adapter(Clinicpro.VirtualMeetings.ZoomAdapter, clinic_id)
```

## Testing and Simulation

### M-Pesa Callback Simulation

The `Clinicpro.MPesaCallbackSimulator` module provides utilities for simulating M-Pesa callbacks:

```elixir
# Simulate STK Push callback
Clinicpro.MPesaCallbackSimulator.simulate_stk_callback(
  "INV-123456",  # invoice reference
  1,             # clinic_id
  1000.0,        # amount
  "254712345678" # phone
)

# Simulate C2B callback
Clinicpro.MPesaCallbackSimulator.simulate_c2b_callback(
  "INV-123456",  # invoice reference
  1,             # clinic_id
  1000.0,        # amount
  "254712345678" # phone
)
```

### Virtual Meeting Testing

The `Clinicpro.VirtualMeetingsTest` module provides comprehensive tests for the virtual meeting integration.

## Security Considerations

- **Payment Isolation**: Each clinic's payments are isolated from others
- **Credential Security**: API credentials are stored securely and not exposed
- **Meeting Security**: Meeting links are generated with random tokens
- **Callback Validation**: All callbacks are validated before processing

## Deployment Considerations

- **Environment Variables**: Configure M-Pesa and virtual meeting credentials via environment variables
- **HTTPS**: Ensure all callback URLs use HTTPS in production
- **Monitoring**: Set up monitoring for payment processing and virtual meeting generation
- **Logging**: Comprehensive logging for debugging and auditing

## Future Enhancements

- **Additional Payment Methods**: Support for card payments, bank transfers, etc.
- **Advanced Meeting Features**: Recording, transcription, waiting rooms
- **Patient Notifications**: SMS/email reminders for upcoming virtual appointments
- **Analytics**: Payment and appointment analytics dashboard for clinics
