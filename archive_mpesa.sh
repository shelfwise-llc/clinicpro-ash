#!/bin/bash

# Create assets/archived directory if it doesn't exist
mkdir -p assets/archived/mpesa

# Copy M-Pesa implementation files to the archive
echo "Archiving M-Pesa implementation..."

# Copy lib files
cp -r lib/clinicpro/mpesa assets/archived/mpesa/
cp lib/clinicpro/mpesa_standalone_test.ex assets/archived/mpesa/
cp lib/clinicpro/mpesa_test.ex assets/archived/mpesa/
cp -r lib/clinicpro_web/components/mpesa_payment_button.ex assets/archived/mpesa/
cp -r lib/clinicpro_web/controllers/mpesa_admin_controller.ex assets/archived/mpesa/
cp -r lib/clinicpro_web/controllers/mpesa_callback_controller.ex assets/archived/mpesa/
cp -r lib/clinicpro_web/templates/mpesa_admin assets/archived/mpesa/
cp lib/clinicpro_web/views/mpesa_admin_view.ex assets/archived/mpesa/

# Copy test files
cp -r test/clinicpro/mpesa assets/archived/mpesa/test_files

# Copy any migration files related to M-Pesa
mkdir -p assets/archived/mpesa/migrations
cp priv/repo/migrations/*mpesa* assets/archived/mpesa/migrations/ 2>/dev/null || :

echo "M-Pesa implementation archived to assets/archived/mpesa"
echo "You can now safely implement Paystack integration"

# Make the script executable
chmod +x archive_mpesa.sh
