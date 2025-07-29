#!/bin/bash

# Comprehensive script to fix all compilation warnings in the ClinicPro codebase
# This script addresses:
# 1. Underscored variables that are being used
# 2. Unused variables that should be prefixed with underscore
# 3. Unused aliases
# 4. Unused functions

echo "=== Fixing underscored variables that are being used ==="
sed -i 's/_transaction/transaction/g' lib/clinicpro/paystack/callback.ex

echo "=== Fixing unused variables ==="
# Fix in paystack/api.ex
sed -i 's/active \\\\ true/_active \\\\ true/g' lib/clinicpro/paystack/api.ex
sed -i 's/\(update_subaccount.*\)clinic_id/\1_clinic_id/g' lib/clinicpro/paystack/api.ex
sed -i 's/defp get_clinic_config(clinic_id)/defp get_clinic_config(_clinic_id)/g' lib/clinicpro/paystack/api.ex

# Fix in paystack/callback.ex
sed -i 's/\({:ok, \)updated_webhook\(.*\)/\1_updated_webhook\2/g' lib/clinicpro/paystack/callback.ex
sed -i 's/event_data, webhook_log/_event_data, _webhook_log/g' lib/clinicpro/paystack/callback.ex
sed -i 's/event_type}, webhook_log/event_type}, _webhook_log/g' lib/clinicpro/paystack/callback.ex
sed -i 's/_unused, _unused/_unused1, _unused2/g' lib/clinicpro/paystack/callback.ex

# Fix in paystack/payment.ex
sed -i 's/reference, description, clinic_id/reference, _description, clinic_id/g' lib/clinicpro/paystack/payment.ex

echo "=== Commenting out unused functions ==="
# Comment out unused functions in paystack/callback.ex
sed -i '/defp create_transaction_from_webhook/,/end/s/^/# /' lib/clinicpro/paystack/callback.ex
sed -i '/defp find_clinic_id_from_reference/,/end/s/^/# /' lib/clinicpro/paystack/callback.ex
sed -i '/defp parse_datetime/,/end/s/^/# /' lib/clinicpro/paystack/callback.ex

echo "=== Fixing unused aliases ==="

# Fix in paystack.ex
sed -i 's/alias Clinicpro.PaystackLegacy.{API, Config, Subaccount, Transaction}/alias Clinicpro.PaystackLegacy.{API, Subaccount, Transaction}/g' lib/clinicpro/paystack.ex

# Fix in paystack/callback.ex
sed -i 's/alias Clinicpro.Paystack.{Config, Transaction, WebhookLog}/alias Clinicpro.Paystack.{Transaction, WebhookLog}/g' lib/clinicpro/paystack/callback.ex

echo "=== Running formatter ==="
cd /home/alex/Projects/Sandbox/Clones_new/clinicpro && mix format

echo "=== Done! ==="
echo "Now run the check_compilation.sh script to see if all warnings are fixed."
