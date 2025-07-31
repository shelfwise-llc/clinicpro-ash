# ClinicPro LiveView + SRP Refactor Plan

## Executive Summary

This document outlines a comprehensive refactor plan to implement LiveView components with Single Responsibility Principle (SRP) architecture in ClinicPro. The refactor will improve code organization, testability, and user experience while maintaining backward compatibility during the transition.

## Current State Analysis

Based on the codebase analysis:

1. **Branch Status**: Currently on `main` branch
2. **Existing Plans**:
   - REFACTOR_PLAN.md exists for auth/paystack refactor
   - Multiple branches exist for different refactor approaches
3. **LiveView Status**: Phoenix LiveView 0.18 is included but not actively used
4. **Component Structure**: Some components exist but no organized LiveView structure

## Proposed Branch Strategy

1. **Archive Current Plans**
   - Move existing refactor plans to `archived_plans/` directory
   - Preserve historical context without interference

2. **Create New Branch**
   - Branch name: `feature/liveview-srp-refactor`
   - Clean separation from existing work

## Refactor Phases

### Phase 1: Foundation Setup (Stage 1)

#### 1.1 Environment Preparation
- [ ] Create `archived_plans/` directory and move existing plans
- [ ] Create new branch `feature/liveview-srp-refactor` from `main`
- [ ] Verify all tests pass in new branch before changes
- [ ] Document current test status for baseline comparison

#### 1.2 Architecture Structure
- [ ] Create new directory structure for SRP-based modules:
  - `lib/clinicpro/accounts/` (user management)
  - `lib/clinicpro/appointments/` (appointment handling)
  - `lib/clinicpro/payments/` (payment processing)
  - `lib/clinicpro/patients/` (patient services)
  - `lib/clinicpro/doctors/` (doctor services)

#### 1.3 LiveView Infrastructure
- [ ] Create `lib/clinicpro_web/live/` directory structure
- [ ] Set up LiveView routing in router.ex
- [ ] Configure LiveView sessions and socket setup
- [ ] Create base LiveView component templates

### Phase 2: Core Component Implementation (Stage 2-3)

#### 2.1 Authentication Components
- [ ] Create `patient_auth_live.ex` for OTP flow
- [ ] Create `doctor_auth_live.ex` for login/dashboard
- [ ] Create `admin_auth_live.ex` for admin login
- [ ] Implement session management in LiveView context

#### 2.2 Appointment Components
- [ ] Create `appointment_booking_live.ex` for patient booking
- [ ] Create `appointment_management_live.ex` for doctor workflow
- [ ] Create `appointment_calendar_live.ex` for visual scheduling
- [ ] Implement real-time appointment updates

#### 2.3 Payment Components
- [ ] Create `payment_processing_live.ex` for invoice payments
- [ ] Create `transaction_history_live.ex` for payment tracking
- [ ] Implement real-time payment status updates

### Phase 3: SRP Module Refactoring (Stage 4-5)

#### 3.1 Handler Implementation
- [ ] Create handler modules for each domain (AppointmentHandler, PaymentHandler, etc.)
- [ ] Move orchestration logic from controllers to handlers
- [ ] Implement clear success/error response patterns

#### 3.2 Service Layer
- [ ] Extract business logic into service modules
- [ ] Implement stateless, pure functions with clear inputs/outputs
- [ ] Add comprehensive error handling with consistent return types

#### 3.3 Finder Modules
- [ ] Create dedicated finder modules for data access
- [ ] Move Ecto queries from controllers/services to finders
- [ ] Implement consistent query patterns and error handling

#### 3.4 Value Objects
- [ ] Create value modules for data representation
- [ ] Standardize JSON responses across the application
- [ ] Implement data transformation and validation logic

### Phase 4: Integration & Testing (Stage 6)

#### 4.1 Component Integration
- [ ] Connect LiveView components to SRP service layer
- [ ] Implement proper state management in LiveView modules
- [] Ensure backward compatibility with existing REST APIs

#### 4.2 Test Implementation
- [ ] Write tests for new SRP modules
- [ ] Create LiveView component tests
- [ ] Verify all existing tests still pass
- [ ] Add integration tests for critical user flows

#### 4.3 Performance Optimization
- [ ] Optimize LiveView payloads
- [ ] Implement proper change tracking
- [ ] Add caching where appropriate

## Directory Structure After Refactor

```
lib/
├── clinicpro/
│   ├── accounts/
│   │   ├── doctor_handler.ex
│   │   ├── doctor_service.ex
│   │   ├── doctor_finder.ex
│   │   ├── doctor_value.ex
│   │   ├── patient_handler.ex
│   │   ├── patient_service.ex
│   │   ├── patient_finder.ex
│   │   └── patient_value.ex
│   ├── appointments/
│   │   ├── appointment_handler.ex
│   │   ├── appointment_service.ex
│   │   ├── appointment_finder.ex
│   │   └── appointment_value.ex
│   ├── payments/
│   │   ├── payment_handler.ex
│   │   ├── paystack_service.ex
│   │   ├── transaction_finder.ex
│   │   └── payment_value.ex
│   ├── patients/
│   │   ├── patient_handler.ex
│   │   ├── patient_service.ex
│   │   ├── patient_finder.ex
│   │   └── patient_value.ex
│   └── doctors/
│       ├── doctor_handler.ex
│       ├── doctor_service.ex
│       ├── doctor_finder.ex
│       └── doctor_value.ex
└── clinicpro_web/
    ├── live/
│   │   ├── patient/
│   │   │   ├── auth_live.ex
│   │   │   ├── dashboard_live.ex
│   │   │   └── appointment_booking_live.ex
│   │   ├── doctor/
│   │   │   ├── auth_live.ex
│   │   │   ├── dashboard_live.ex
│   │   │   └── appointment_management_live.ex
│   │   ├── admin/
│   │   │   ├── auth_live.ex
│   │   │   └── dashboard_live.ex
│   │   └── components/
│   │       ├── auth_components.ex
│   │       ├── appointment_components.ex
│   │       ├── payment_components.ex
│   │       └── core_components.ex
    ├── controllers/ (gradually deprecated)
    └── views/ (gradually deprecated)
```

## Success Criteria

### Technical Requirements
- [ ] All existing functionality preserved
- [ ] All tests pass (both existing and new)
- [ ] No compilation warnings
- [ ] Backward compatibility maintained
- [ ] Performance meets or exceeds current levels

### Code Quality
- [ ] SRP modules have single, clear responsibilities
- [ ] LiveView components are focused and reusable
- [ ] Consistent error handling across all modules
- [ ] Comprehensive test coverage

### User Experience
- [ ] Improved responsiveness with LiveView
- [ ] Real-time updates where appropriate
- [ ] Consistent UI/UX across all components
- [ ] No degradation in accessibility

## Risk Mitigation

1. **Backward Compatibility**: Maintain REST APIs during transition
2. **Testing**: Comprehensive test coverage before and after changes
3. **Performance**: Monitor and optimize LiveView payloads
4. **Deployment**: Gradual rollout with rollback capability

## Timeline

Next 48 hours.

## Next Steps

1. Create archived_plans directory
2. Move existing plans to archived_plans
3. Create feature/liveview-srp-refactor branch
4. Begin Phase 1 implementation
5. Set up CI to ensure tests pass on new branch