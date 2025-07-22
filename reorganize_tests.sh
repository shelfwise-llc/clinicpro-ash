#!/bin/bash

# Script to reorganize test files in the ClinicPro project
# This script implements the organization plan from docs/test_organization_plan.md

echo "Starting test files reorganization..."

# Create necessary directories
echo "Creating directories..."
mkdir -p test/clinicpro/mpesa
mkdir -p test/clinicpro/admin_bypass
mkdir -p test/clinicpro/auth
mkdir -p test/clinicpro/workflow
mkdir -p test/clinicpro/integration
mkdir -p test/support/scripts
mkdir -p test/support/shell
mkdir -p docs/mpesa

# Move M-Pesa test files
echo "Moving M-Pesa test files..."
[ -f mpesa_core_test.exs ] && mv mpesa_core_test.exs test/clinicpro/mpesa/core_test.exs
[ -f mpesa_focused_test.exs ] && mv mpesa_focused_test.exs test/clinicpro/mpesa/focused_test.exs
[ -f mpesa_module_test.exs ] && mv mpesa_module_test.exs test/clinicpro/mpesa/module_test.exs
[ -f mpesa_multi_clinic_test.exs ] && mv mpesa_multi_clinic_test.exs test/clinicpro/mpesa/multi_clinic_test.exs
[ -f mpesa_sandbox_test.exs ] && mv mpesa_sandbox_test.exs test/clinicpro/mpesa/sandbox_test.exs
[ -f mpesa_standalone_test.exs ] && mv mpesa_standalone_test.exs test/clinicpro/mpesa/standalone_test.exs
[ -f test_mpesa.exs ] && mv test_mpesa.exs test/clinicpro/mpesa/mpesa_test.exs
[ -f test_mpesa_only.exs ] && mv test_mpesa_only.exs test/clinicpro/mpesa/mpesa_only_test.exs

# Move admin bypass test files
echo "Moving admin bypass test files..."
[ -f test_admin_bypass.exs ] && mv test_admin_bypass.exs test/clinicpro/admin_bypass/admin_bypass_test.exs
[ -f test_bypass.exs ] && mv test_bypass.exs test/clinicpro/admin_bypass/bypass_test.exs

# Move auth test files
echo "Moving auth test files..."
[ -f test_ash_authentication.exs ] && mv test_ash_authentication.exs test/clinicpro/auth/ash_authentication_test.exs
[ -f test_auth_minimal.exs ] && mv test_auth_minimal.exs test/clinicpro/auth/auth_minimal_test.exs
[ -f test_auth_placeholder.exs ] && mv test_auth_placeholder.exs test/clinicpro/auth/auth_placeholder_test.exs

# Move workflow test files
echo "Moving workflow test files..."
[ -f test_workflow.exs ] && mv test_workflow.exs test/clinicpro/workflow/workflow_test.exs
[ -f test_workflow_logic.exs ] && mv test_workflow_logic.exs test/clinicpro/workflow/workflow_logic_test.exs

# Move integration test files
echo "Moving integration test files..."
[ -f test_doctor_flow_bypass.exs ] && mv test_doctor_flow_bypass.exs test/clinicpro/integration/doctor_flow_bypass_test.exs

# Move script files
echo "Moving script files..."
[ -f run_admin_bypass.exs ] && mv run_admin_bypass.exs test/support/scripts/run_admin_bypass.exs
[ -f run_bypass_server.exs ] && mv run_bypass_server.exs test/support/scripts/run_bypass_server.exs
[ -f run_controller_tests.exs ] && mv run_controller_tests.exs test/support/scripts/run_controller_tests.exs
[ -f run_controller_tests_only.exs ] && mv run_controller_tests_only.exs test/support/scripts/run_controller_tests_only.exs
[ -f run_isolated_tests.exs ] && mv run_isolated_tests.exs test/support/scripts/run_isolated_tests.exs
[ -f run_workflow_tests.exs ] && mv run_workflow_tests.exs test/support/scripts/run_workflow_tests.exs
[ -f simulate_doctor_api.exs ] && mv simulate_doctor_api.exs test/support/scripts/simulate_doctor_api.exs

# Move shell scripts
echo "Moving shell scripts..."
[ -f run_bypass_server.sh ] && mv run_bypass_server.sh test/support/shell/run_bypass_server.sh
[ -f run_doctor_tests.sh ] && mv run_doctor_tests.sh test/support/shell/run_doctor_tests.sh
[ -f run_isolated_doctor_tests.sh ] && mv run_isolated_doctor_tests.sh test/support/shell/run_isolated_doctor_tests.sh
[ -f run_isolated_tests.sh ] && mv run_isolated_tests.sh test/support/shell/run_isolated_tests.sh
[ -f setup_admin_bypass.sh ] && mv setup_admin_bypass.sh test/support/shell/setup_admin_bypass.sh

# Move documentation
echo "Moving documentation..."
[ -f README_MPESA.md ] && mv README_MPESA.md docs/mpesa/README.md

# Create wrapper scripts in the root directory
echo "Creating wrapper scripts..."

# Create M-Pesa test runner
cat > run_mpesa_tests.exs << 'EOF'
# Run all M-Pesa tests
IO.puts("Running all M-Pesa tests...")
Code.require_file("test/support/scripts/run_mpesa_tests.exs")
EOF

# Create the actual M-Pesa test runner in the new location
cat > test/support/scripts/run_mpesa_tests.exs << 'EOF'
ExUnit.start()

# Run all M-Pesa tests
IO.puts("Loading M-Pesa tests...")
Enum.each(Path.wildcard("test/clinicpro/mpesa/*_test.exs"), &Code.require_file/1)
EOF

# Create admin bypass test runner
cat > run_admin_bypass_tests.exs << 'EOF'
# Run all admin bypass tests
IO.puts("Running all admin bypass tests...")
Code.require_file("test/support/scripts/run_admin_bypass_tests.exs")
EOF

# Create the actual admin bypass test runner in the new location
cat > test/support/scripts/run_admin_bypass_tests.exs << 'EOF'
ExUnit.start()

# Run all admin bypass tests
IO.puts("Loading admin bypass tests...")
Enum.each(Path.wildcard("test/clinicpro/admin_bypass/*_test.exs"), &Code.require_file/1)
EOF

# Create workflow test runner
cat > run_workflow_tests.exs << 'EOF'
# Run all workflow tests
IO.puts("Running all workflow tests...")
Code.require_file("test/support/scripts/run_workflow_tests.exs")
EOF

# Create the actual workflow test runner in the new location
cat > test/support/scripts/run_workflow_tests.exs << 'EOF'
ExUnit.start()

# Run all workflow tests
IO.puts("Loading workflow tests...")
Enum.each(Path.wildcard("test/clinicpro/workflow/*_test.exs"), &Code.require_file/1)
EOF

# Create shell script wrapper for running bypass server
cat > run_bypass_server.sh << 'EOF'
#!/bin/bash
# Run bypass server
echo "Starting bypass server..."
bash test/support/shell/run_bypass_server.sh
EOF
chmod +x run_bypass_server.sh

echo "Reorganization complete!"
echo "Please check the files and update any references as needed."
echo "You may need to update import/require statements in the moved files."
