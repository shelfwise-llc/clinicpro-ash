# ClinicPro - Ash Framework Implementation

ClinicPro is a medical clinic management system built with Elixir, Phoenix, and the Ash Framework. This system manages appointments, patient records, and doctor workflows in a modern, secure web application.

## Current Status

The project is currently under active development with a focus on implementing the doctor workflow. We're using Ash Framework 2.17.x with AshAuthentication 3.12.4 and ash_phoenix 1.3.x.

### Known Issues

There are currently compilation issues with AshAuthentication's magic link strategy. The error occurs in the transformer with: `key :type not found in: nil`. This is being addressed by properly configuring the magic link strategy in the User resource.

## Development Approach

To allow development to continue while addressing the AshAuthentication issues, we've implemented a bypass approach:

1. **Isolated Test Runner**: A standalone test environment that doesn't depend on the main application
2. **Mock Implementations**: Mock structs for User, Doctor, Patient, and Appointment
3. **Workflow State Management**: A module to simulate the controller's workflow state
4. **Bypass Controller**: A controller implementation that works without AshAuthentication

## Doctor Flow Implementation

The doctor workflow consists of the following steps:

1. List appointments
2. Access appointment details
3. Fill medical details
4. Record diagnosis
5. Complete appointment

## Running Tests

### Isolated Tests

To run the isolated doctor flow tests (bypassing AshAuthentication):

```bash
./run_isolated_doctor_tests.sh
```

### Standard Tests

Once AshAuthentication issues are resolved:

```bash
mix test
```

## Setup and Installation

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Using the Bypass Controller

While AshAuthentication issues are being resolved, you can use the bypass controller:

1. Import the bypass routes in your main router:
   ```elixir
   # In lib/clinicpro_web/router.ex
   import ClinicproWeb.RouterBypass

   # Then in the appropriate scope:
   doctor_flow_bypass_routes()
   ```

2. Access the doctor flow at `/doctor/appointments`

## Authentication

The project uses AshAuthentication with magic link strategy. The configuration approach is:

1. Minimal configuration at the API level
2. Magic link strategy configuration at the User resource level
3. MagicLinkSender module implementing the required behavior
4. Token configuration at the API level only

## Test Organization

The test files have been reorganized into a more structured directory layout:

### Test Directory Structure

```
test/
├── clinicpro/
│   ├── mpesa/             # M-Pesa integration tests
│   ├── admin_bypass/      # Admin bypass tests
│   ├── auth/              # Authentication tests
│   ├── workflow/          # Workflow tests
│   └── integration/       # Integration tests
│
└── support/
    ├── scripts/           # Test runner scripts
    └── shell/             # Shell scripts for test setup
```

### Running Tests

To run specific test groups, use the following scripts:

- `mix run run_mpesa_tests.exs` - Run all M-Pesa tests
- `mix run run_admin_bypass_tests.exs` - Run all admin bypass tests
- `mix run run_workflow_tests.exs` - Run all workflow tests

For more detailed information about the M-Pesa integration, see the [M-Pesa documentation](docs/mpesa/README.md).

## M-Pesa and Virtual Meetings Integration

The project includes a comprehensive integration between M-Pesa payment processing and virtual meeting generation with the following features:

- **Multi-tenant architecture**: Each clinic has isolated configurations for M-Pesa and virtual meetings
- **Real API integrations**: Support for Google Meet and Zoom with proper authentication
- **Fallback mechanisms**: SimpleAdapter fallback for API failures
- **Comprehensive testing**: Unit, integration, and real API tests

For detailed information about this integration, see the following documentation:

- [Integration Summary](docs/mpesa_virtual_meetings_integration_summary.md)
- [Deployment Guide](docs/mpesa_virtual_meetings_deployment.md)
- [Testing Checklist](docs/integration_testing_checklist.md)

## Learn More

* Ash Framework: https://ash-hq.org/
* AshAuthentication: https://hexdocs.pm/ash_authentication
* Phoenix Framework: https://www.phoenixframework.org/
* Elixir: https://elixir-lang.org/
