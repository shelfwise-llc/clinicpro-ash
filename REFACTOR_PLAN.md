# ClinicPro Authentication & Payment Refactor Plan

## Current Status
- ✅ **Archive Branch Created**: `archive/pre-auth-refactor`
- ✅ **Development Branch**: `feature/auth-paystack-refactor`
- ✅ **Compilation**: Working (with warnings)
- ❌ **Tests**: Failing due to Mox configuration
- ❌ **Authentication**: AshAuthentication disabled due to compatibility issues

## Phase 1: Fix Critical Issues

### 1.1 Fix Test Infrastructure
- [ ] Fix Mox configuration in test_helper.exs
- [ ] Resolve mock module redefinition warnings
- [ ] Fix undefined function errors in tests
- [ ] Ensure basic test suite passes

### 1.2 Clean Up Compilation Warnings
- [ ] Fix underscored variable usage in admin_controller.ex
- [ ] Fix virtual meetings adapter implementation
- [ ] Remove unused functions and aliases
- [ ] Fix undefined module references

## Phase 2: Authentication Refactor

### 2.1 Remove AshAuthentication
- [ ] Remove AshAuthentication dependencies from mix.exs
- [ ] Clean up disabled authentication code
- [ ] Remove AshAuthentication.Phoenix routes

### 2.2 Implement Guardian JWT Authentication
- [ ] Add Guardian and related dependencies
- [ ] Create User schema with email/password
- [ ] Implement login/logout controllers
- [ ] Add password hashing with Argon2
- [ ] Create JWT token management
- [ ] Add "forgot password" flow with email

### 2.3 Update Multi-Tenant Architecture
- [ ] Ensure clinic isolation in authentication
- [ ] Update user roles and permissions
- [ ] Test clinic-specific user access

## Phase 3: Payment Integration

### 3.1 Complete Paystack Integration
- [ ] Fix missing Paystack.API module
- [ ] Implement Paystack.Config for multi-tenant setup
- [ ] Create Paystack.Http module for API calls
- [ ] Add webhook handling for payment confirmations

### 3.2 Invoice-Payment Integration
- [ ] Connect invoice UI to Paystack payments
- [ ] Add payment buttons to invoice templates
- [ ] Implement payment status updates
- [ ] Test end-to-end payment flow

### 3.3 Remove M-Pesa Integration
- [ ] Remove M-Pesa modules and dependencies
- [ ] Clean up M-Pesa references in payment processor
- [ ] Update multi-tenant architecture to use Paystack only

## Phase 4: Testing & Deployment

### 4.1 Comprehensive Testing
- [ ] Fix all test failures
- [ ] Add tests for new authentication flow
- [ ] Test multi-tenant payment processing
- [ ] Verify clinic isolation works correctly

### 4.2 CI/CD Pipeline
- [ ] Ensure all GitHub Actions pass
- [ ] Test Railway deployment
- [ ] Verify production environment variables
- [ ] Test database migrations

### 4.3 Merge to Main
- [ ] Code review and cleanup
- [ ] Update documentation
- [ ] Merge feature branch to main
- [ ] Deploy to production

## Success Criteria

### ✅ Authentication Working
- Users can register/login with email/password
- JWT tokens work correctly
- Clinic isolation maintained
- Password reset flow functional

### ✅ Payments Working
- Invoices can trigger Paystack payments
- Payment status updates correctly
- Multi-tenant payment isolation
- Webhook processing works

### ✅ CI/CD Pipeline
- All tests pass
- Application compiles without warnings
- Railway deployment successful
- Production environment stable

## Rollback Plan
- Archive branch: `archive/pre-auth-refactor` contains working state
- Can revert to this branch if issues arise
- All changes are in feature branch until fully tested

## Key Files to Modify

### Authentication
- `mix.exs` - Dependencies
- `lib/clinicpro/accounts/` - User management
- `lib/clinicpro_web/controllers/auth_controller.ex` - New auth controller
- `lib/clinicpro_web/router.ex` - Auth routes

### Payments
- `lib/clinicpro/paystack/` - Complete Paystack integration
- `lib/clinicpro/invoices/payment_processor.ex` - Update for Paystack
- `lib/clinicpro_web/templates/invoice/` - Payment UI

### Testing
- `test/test_helper.exs` - Fix Mox configuration
- `test/support/` - Clean up mock modules
- Add comprehensive integration tests

## Timeline:
- **Day 1**: Fix tests and warnings
- **Days 2-3**: Authentication refactor
- **Days 4-5**: Payment integration
- **Day 6**: Testing and deployment
