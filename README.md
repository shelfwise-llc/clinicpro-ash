# ClinicPro - Medical Clinic Management System

ClinicPro is a medical clinic management system built with Elixir, Phoenix, and the Ash Framework. This system manages appointments, patient records, and doctor workflows in a modern, secure web application.

## Current Status

The project is currently under active development with the following key features:

1. **Multi-tenant Architecture**: Each clinic has isolated data and configurations
2. **Paystack Payment Integration**: Secure payment processing (M-Pesa integration is disabled)
3. **Guardian JWT Authentication**: Secure authentication with multi-tenant support
4. **Doctor and Patient Workflows**: Complete appointment management system

### Payment Processing

- **Paystack**: Active payment gateway with full multi-tenant support
- **M-Pesa**: Integration is currently disabled (code is preserved in comments for reference)

### Authentication System

The application uses Guardian JWT authentication with the following features:

1. **JWT Token-based Authentication**: Secure, stateless authentication
2. **Role-based Access Control**: Admin, doctor, and patient roles
3. **Multi-tenant Isolation**: Users can only access their clinic's resources
4. **Password Reset Flow**: Complete forgot/reset password functionality

## Development Approach

To ensure maintainable and robust code, we follow these practices:

1. **Multi-tenant Architecture**: All features respect clinic isolation
2. **Comprehensive Testing**: Unit and integration tests for critical paths
3. **Phased Refactoring**: Systematic approach to code improvements

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

## M-Pesa Integration (Disabled)

The project previously included M-Pesa integration, which has been disabled in favor of Paystack. The M-Pesa code remains in the codebase (commented out) for reference purposes.

### Paystack Integration

The project now uses Paystack as the primary payment gateway:

* **Multi-tenant Architecture**: Each clinic has its own Paystack configuration
* **Payment Processing**: Supports standard Paystack payment flow
* **Transaction Isolation**: Transactions are isolated by clinic
* **Admin Interface**: Dedicated admin interface for managing Paystack configurations

### Components

* `Clinicpro.Paystack` - Main module in `/lib/clinicpro/paystack/paystack.ex`
* `Clinicpro.Paystack.Config` - Configuration management with multi-tenant support
* `Clinicpro.Paystack.API` - API client for Paystack
* `Clinicpro.Paystack.Transaction` - Transaction management with clinic isolation
* `Clinicpro.Paystack.Callback` - Webhook handling for payment notifications

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

## Learn More

* Ash Framework: https://ash-hq.org/
* AshAuthentication: https://hexdocs.pm/ash_authentication
* Phoenix Framework: https://www.phoenixframework.org/
* Elixir: https://elixir-lang.org/
# CI/CD Pipeline Status
