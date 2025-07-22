#!/bin/bash

# Script to reorganize remaining test files in the ClinicPro project

echo "Starting additional test files reorganization..."

# Create necessary directories if they don't exist
echo "Creating directories..."
mkdir -p test/clinicpro/auth
mkdir -p test/clinicpro/workflow
mkdir -p test/support/scripts
mkdir -p test/support/demo

# Move demo files
echo "Moving demo files..."
[ -f demo_auth.exs ] && mv demo_auth.exs test/support/demo/demo_auth.exs
[ -f demo_workflow.exs ] && mv demo_workflow.exs test/support/demo/demo_workflow.exs

# Move fix files to auth directory
echo "Moving fix files..."
[ -f fix_all_resources.exs ] && mv fix_all_resources.exs test/clinicpro/auth/fix_all_resources.exs
[ -f fix_ash_authentication.exs ] && mv fix_ash_authentication.exs test/clinicpro/auth/fix_ash_authentication.exs
[ -f fix_ash_authentication_simple.exs ] && mv fix_ash_authentication_simple.exs test/clinicpro/auth/fix_ash_authentication_simple.exs
[ -f fix_ash_policies.exs ] && mv fix_ash_policies.exs test/clinicpro/auth/fix_ash_policies.exs

# Create wrapper scripts for demo files
echo "Creating wrapper scripts..."

# Create demo auth wrapper
cat > demo_auth.exs << 'EOF'
# Run demo auth
IO.puts("Running demo auth...")
Code.require_file("test/support/demo/demo_auth.exs")
EOF

# Create demo workflow wrapper
cat > demo_workflow.exs << 'EOF'
# Run demo workflow
IO.puts("Running demo workflow...")
Code.require_file("test/support/demo/demo_workflow.exs")
EOF

# Create fix ash authentication wrapper
cat > fix_ash_authentication.exs << 'EOF'
# Run fix ash authentication
IO.puts("Running fix ash authentication...")
Code.require_file("test/clinicpro/auth/fix_ash_authentication.exs")
EOF

# Create fix ash authentication simple wrapper
cat > fix_ash_authentication_simple.exs << 'EOF'
# Run fix ash authentication simple
IO.puts("Running fix ash authentication simple...")
Code.require_file("test/clinicpro/auth/fix_ash_authentication_simple.exs")
EOF

# Create fix ash policies wrapper
cat > fix_ash_policies.exs << 'EOF'
# Run fix ash policies
IO.puts("Running fix ash policies...")
Code.require_file("test/clinicpro/auth/fix_ash_policies.exs")
EOF

# Create fix all resources wrapper
cat > fix_all_resources.exs << 'EOF'
# Run fix all resources
IO.puts("Running fix all resources...")
Code.require_file("test/clinicpro/auth/fix_all_resources.exs")
EOF

echo "Additional reorganization complete!"
echo "Please check the files and update any references as needed."
echo "You may need to update import/require statements in the moved files."