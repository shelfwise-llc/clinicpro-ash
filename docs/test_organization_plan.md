# Test Files Organization Plan

## Current Issues

Currently, there are numerous test files and scripts located in the root directory of the project, which:
- Makes it difficult to find specific tests
- Clutters the root directory
- Doesn't follow Elixir/Phoenix project structure conventions
- Creates confusion about which tests to run for specific features

## Proposed Directory Structure

We'll reorganize the files into the following structure:

```
clinicpro/
├── test/
│   ├── clinicpro/
│   │   ├── mpesa/
│   │   │   ├── core_test.exs             # Moved from mpesa_core_test.exs
│   │   │   ├── focused_test.exs          # Moved from mpesa_focused_test.exs
│   │   │   ├── module_test.exs           # Moved from mpesa_module_test.exs
│   │   │   ├── multi_clinic_test.exs     # Moved from mpesa_multi_clinic_test.exs
│   │   │   ├── sandbox_test.exs          # Moved from mpesa_sandbox_test.exs
│   │   │   ├── standalone_test.exs       # Moved from mpesa_standalone_test.exs
│   │   │   ├── mpesa_test.exs            # Moved from test_mpesa.exs
│   │   │   └── mpesa_only_test.exs       # Moved from test_mpesa_only.exs
│   │   │
│   │   ├── admin_bypass/
│   │   │   ├── admin_bypass_test.exs     # Moved from test_admin_bypass.exs
│   │   │   └── bypass_test.exs           # Moved from test_bypass.exs
│   │   │
│   │   ├── auth/
│   │   │   ├── ash_authentication_test.exs  # Moved from test_ash_authentication.exs
│   │   │   ├── auth_minimal_test.exs     # Moved from test_auth_minimal.exs
│   │   │   ├── auth_placeholder_test.exs # Moved from test_auth_placeholder.exs
│   │   │   ├── fix_all_resources.exs     # Moved from fix_all_resources.exs
│   │   │   ├── fix_ash_authentication.exs # Moved from fix_ash_authentication.exs
│   │   │   ├── fix_ash_authentication_simple.exs # Moved from fix_ash_authentication_simple.exs
│   │   │   └── fix_ash_policies.exs      # Moved from fix_ash_policies.exs
│   │   │
│   │   ├── workflow/
│   │   │   ├── workflow_test.exs         # Moved from test_workflow.exs
│   │   │   └── workflow_logic_test.exs   # Moved from test_workflow_logic.exs
│   │   │
│   │   └── integration/
│   │       ├── doctor_flow_bypass_test.exs  # Moved from test_doctor_flow_bypass.exs
│   │       └── real_api_integration_test.exs  # Already in the right place
│   │
│   └── support/
│       ├── scripts/
│       │   ├── run_admin_bypass.exs      # Moved from run_admin_bypass.exs
│       │   ├── run_bypass_server.exs     # Moved from run_bypass_server.exs
│       │   ├── run_controller_tests.exs  # Moved from run_controller_tests.exs
│       │   ├── run_controller_tests_only.exs # Moved from run_controller_tests_only.exs
│       │   ├── run_isolated_tests.exs    # Moved from run_isolated_tests.exs
│       │   ├── run_workflow_tests.exs    # Moved from run_workflow_tests.exs
│       │   ├── run_mpesa_tests.exs       # New file for running M-Pesa tests
│       │   ├── run_admin_bypass_tests.exs # New file for running admin bypass tests
│       │   └── simulate_doctor_api.exs   # Moved from simulate_doctor_api.exs
│       │
│       ├── shell/
│       │   ├── run_bypass_server.sh      # Moved from run_bypass_server.sh
│       │   ├── run_doctor_tests.sh       # Moved from run_doctor_tests.sh
│       │   ├── run_isolated_doctor_tests.sh # Moved from run_isolated_doctor_tests.sh
│       │   ├── run_isolated_tests.sh     # Moved from run_isolated_tests.sh
│       │   └── setup_admin_bypass.sh     # Moved from setup_admin_bypass.sh
│       │
│       └── demo/
│           ├── demo_auth.exs             # Moved from demo_auth.exs
│           └── demo_workflow.exs         # Moved from demo_workflow.exs
│
├── docs/
│   ├── mpesa/
│   │   └── README.md                     # Moved from README_MPESA.md
│   │
│   ├── mpesa_virtual_meetings_integration.md       # Already in the right place
│   ├── mpesa_virtual_meetings_deployment.md        # Already in the right place
│   ├── mpesa_virtual_meetings_integration_summary.md # Already in the right place
│   └── integration_testing_checklist.md            # Already in the right place
│
└── README.md                             # Main README stays in root
```

## Implementation Steps

1. Create the necessary directories:
   ```bash
   mkdir -p test/clinicpro/mpesa
   mkdir -p test/clinicpro/admin_bypass
   mkdir -p test/clinicpro/auth
   mkdir -p test/clinicpro/workflow
   mkdir -p test/clinicpro/integration
   mkdir -p test/support/scripts
   mkdir -p test/support/shell
   mkdir -p test/support/demo
   mkdir -p docs/mpesa
   ```

2. Move test files to their appropriate directories:
   ```bash
   # Move M-Pesa test files
   mv mpesa_core_test.exs test/clinicpro/mpesa/core_test.exs
   mv mpesa_focused_test.exs test/clinicpro/mpesa/focused_test.exs
   mv mpesa_module_test.exs test/clinicpro/mpesa/module_test.exs
   mv mpesa_multi_clinic_test.exs test/clinicpro/mpesa/multi_clinic_test.exs
   mv mpesa_sandbox_test.exs test/clinicpro/mpesa/sandbox_test.exs
   mv mpesa_standalone_test.exs test/clinicpro/mpesa/standalone_test.exs
   mv test_mpesa.exs test/clinicpro/mpesa/mpesa_test.exs
   mv test_mpesa_only.exs test/clinicpro/mpesa/mpesa_only_test.exs

   # Move admin bypass test files
   mv test_admin_bypass.exs test/clinicpro/admin_bypass/admin_bypass_test.exs
   mv test_bypass.exs test/clinicpro/admin_bypass/bypass_test.exs

   # Move auth test files
   mv test_ash_authentication.exs test/clinicpro/auth/ash_authentication_test.exs
   mv test_auth_minimal.exs test/clinicpro/auth/auth_minimal_test.exs
   mv test_auth_placeholder.exs test/clinicpro/auth/auth_placeholder_test.exs
   mv fix_all_resources.exs test/clinicpro/auth/fix_all_resources.exs
   mv fix_ash_authentication.exs test/clinicpro/auth/fix_ash_authentication.exs
   mv fix_ash_authentication_simple.exs test/clinicpro/auth/fix_ash_authentication_simple.exs
   mv fix_ash_policies.exs test/clinicpro/auth/fix_ash_policies.exs

   # Move workflow test files
   mv test_workflow.exs test/clinicpro/workflow/workflow_test.exs
   mv test_workflow_logic.exs test/clinicpro/workflow/workflow_logic_test.exs

   # Move integration test files
   mv test_doctor_flow_bypass.exs test/clinicpro/integration/doctor_flow_bypass_test.exs

   # Move script files
   mv run_admin_bypass.exs test/support/scripts/run_admin_bypass.exs
   mv run_bypass_server.exs test/support/scripts/run_bypass_server.exs
   mv run_controller_tests.exs test/support/scripts/run_controller_tests.exs
   mv run_controller_tests_only.exs test/support/scripts/run_controller_tests_only.exs
   mv run_isolated_tests.exs test/support/scripts/run_isolated_tests.exs
   mv run_workflow_tests.exs test/support/scripts/run_workflow_tests.exs
   mv simulate_doctor_api.exs test/support/scripts/simulate_doctor_api.exs

   # Move shell scripts
   mv run_bypass_server.sh test/support/shell/run_bypass_server.sh
   mv run_doctor_tests.sh test/support/shell/run_doctor_tests.sh
   mv run_isolated_doctor_tests.sh test/support/shell/run_isolated_doctor_tests.sh
   mv run_isolated_tests.sh test/support/shell/run_isolated_tests.sh
   mv setup_admin_bypass.sh test/support/shell/setup_admin_bypass.sh

   # Move demo files
   mv demo_auth.exs test/support/demo/demo_auth.exs
   mv demo_workflow.exs test/support/demo/demo_workflow.exs

   # Move documentation
   mv README_MPESA.md docs/mpesa/README.md
   ```

3. Update references in files:
   - Update any `require` or `import` statements in the moved files
   - Update any file paths referenced in scripts
   - Update documentation references

4. Update the main README.md to reflect the new structure:
   ```markdown
   ## Testing

   Tests are organized by feature in the `test/clinicpro/` directory:

   - M-Pesa tests: `test/clinicpro/mpesa/`
   - Admin bypass tests: `test/clinicpro/admin_bypass/`
   - Authentication tests: `test/clinicpro/auth/`
   - Workflow tests: `test/clinicpro/workflow/`
   - Integration tests: `test/clinicpro/integration/`

   Helper scripts for running tests are located in:

   - Elixir scripts: `test/support/scripts/`
   - Shell scripts: `test/support/shell/`
   ```

5. Create a new script to run specific test groups:
   ```elixir
   # test/support/scripts/run_mpesa_tests.exs

   ExUnit.start()

   # Run all M-Pesa tests
   Enum.each(Path.wildcard("test/clinicpro/mpesa/*_test.exs"), &Code.require_file/1)
   ```

## Additional Implementation Steps

1. Run the second reorganization script:
   ```bash
   chmod +x reorganize_remaining_tests.sh
   ./reorganize_remaining_tests.sh
   ```

2. Verify that all test files have been moved to their appropriate locations:
   ```bash
   find . -maxdepth 1 -name "*.exs" | grep -v "mix.exs" | grep -v "run_.*\.exs" | grep -v "demo_.*\.exs" | grep -v "fix_.*\.exs"
   ```

3. Update any references in the moved files to reflect their new locations.

4. Run the tests to ensure everything still works:
   ```bash
   mix test
   ```

## Benefits of Reorganization

1. **Improved organization**: Files are grouped by feature and function
2. **Better discoverability**: Easier to find specific tests
3. **Cleaner root directory**: Root directory contains only essential files
4. **Conventional structure**: Follows Elixir/Phoenix project structure conventions
5. **Easier maintenance**: Related files are grouped together
6. **Simplified test running**: Can run tests by feature group

## Potential Issues and Mitigations

1. **Breaking existing scripts**:
   - Update all scripts to reference the new file paths
   - Create wrapper scripts in the root directory that call the moved scripts

2. **CI/CD pipeline changes**:
   - Update CI/CD configuration to reference the new file paths

3. **Team awareness**:
   - Document the changes in the README
   - Notify the team about the reorganization
