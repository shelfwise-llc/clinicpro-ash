# ClinicPro Virtual Meeting Integration

This document provides an overview of the virtual meeting integration in ClinicPro, which enables automatic creation of virtual meeting links for virtual appointments upon payment confirmation.

## Architecture

The virtual meeting integration follows an adapter pattern, allowing for multiple video conferencing providers to be supported through a common interface. The system is designed to be:

1. **Extensible**: New meeting providers can be added by implementing the adapter behaviour
2. **Configurable**: Meeting providers can be switched via configuration
3. **Multi-tenant**: Different clinics can use different meeting providers
4. **Fault-tolerant**: Falls back to simple URL generation if provider APIs fail

### Components

- **Adapter Behaviour** (`Clinicpro.VirtualMeetings.Adapter`): Defines the interface that all meeting adapters must implement
- **Configuration** (`Clinicpro.VirtualMeetings.Config`): Manages adapter selection and configuration
- **Simple Adapter** (`Clinicpro.VirtualMeetings.SimpleAdapter`): Generates predictable meeting URLs without external API calls
- **Google Meet Adapter** (`Clinicpro.VirtualMeetings.GoogleMeetAdapter`): Creates meetings via Google Calendar API
- **Zoom Adapter** (`Clinicpro.VirtualMeetings.ZoomAdapter`): Creates meetings via Zoom API
- **Invoice Processing** (`Clinicpro.Invoices`): Integrates with the adapter system to create meetings upon payment

## Configuration

The virtual meeting system can be configured via application environment variables:

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

You can also set these configurations at runtime:

```elixir
# Set the adapter to use
Clinicpro.VirtualMeetings.Config.set_adapter(Clinicpro.VirtualMeetings.GoogleMeetAdapter)

# Set the base URL for simple adapter
Clinicpro.VirtualMeetings.Config.set_base_url("https://meet.example.com")

# Set Google API credentials
Clinicpro.VirtualMeetings.Config.set_google_credentials(%{...})

# Set Zoom API credentials
Clinicpro.VirtualMeetings.Config.set_zoom_credentials(%{...})
```

## Multi-tenant Support

The system supports multi-tenant configuration, allowing different clinics to use different meeting providers:

```elixir
# Set adapter for a specific clinic
Clinicpro.VirtualMeetings.Config.set_adapter(Clinicpro.VirtualMeetings.ZoomAdapter, clinic_id)

# Create a meeting using a clinic-specific adapter
Clinicpro.VirtualMeetings.Adapter.create_meeting(appointment, [], clinic_id)
```

## Payment Flow Integration

When a payment is completed for a virtual appointment:

1. The `Clinicpro.Invoices.process_completed_payment/1` function is called
2. If the appointment is virtual, `handle_virtual_appointment/1` is invoked
3. The configured virtual meeting adapter is used to create a meeting
4. The appointment is updated with the meeting link and data
5. If the adapter fails, a fallback link is generated

## Implementing New Adapters

To implement a new virtual meeting adapter:

1. Create a new module that implements the `Clinicpro.VirtualMeetings.Adapter` behaviour
2. Implement the required callbacks: `create_meeting/2`, `update_meeting/2`, and `delete_meeting/1`
3. Configure the system to use your adapter

Example:

```elixir
defmodule Clinicpro.VirtualMeetings.MyAdapter do
  @behaviour Clinicpro.VirtualMeetings.Adapter

  @impl true
  def create_meeting(appointment, opts) do
    # Implementation
    {:ok, %{url: "https://example.com/meeting/123"}}
  end

  @impl true
  def update_meeting(appointment, opts) do
    # Implementation
    {:ok, %{url: "https://example.com/meeting/123"}}
  end

  @impl true
  def delete_meeting(appointment) do
    # Implementation
    :ok
  end
end
```

## Testing

To test the virtual meeting integration:

1. Configure the system to use the `SimpleAdapter` for testing
2. Create a virtual appointment
3. Simulate a payment completion
4. Verify that a meeting link is generated and the appointment is updated

## Security Considerations

- Meeting links should be unique and unpredictable
- Credentials for external APIs should be stored securely
- Access to meeting links should be restricted to authorized users
- Consider implementing additional authentication for meeting access

## Future Enhancements

- Implement real Google Meet integration using Google Calendar API
- Implement real Zoom integration using Zoom API
- Add support for Microsoft Teams
- Implement meeting reminders and notifications
- Add support for recording meetings
- Implement meeting analytics and reporting
