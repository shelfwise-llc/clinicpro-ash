#!/bin/bash

# Comprehensive fix for all compilation warnings
echo "🔧 Fixing all compilation warnings..."

# Fix PaystackAdminController
echo "Fixing PaystackAdminController..."
sed -i 's/Callback.retry_webhook(id, _clinic_id)/Callback.retry_webhook(id, clinic_id)/g' lib/clinicpro_web/controllers/paystack_admin_controller.ex
sed -i 's/Routes.paystack_admin_path(conn, :webhook_details, _clinic_id, id)/Routes.paystack_admin_path(conn, :webhook_details, clinic_id, id)/g' lib/clinicpro_web/controllers/paystack_admin_controller.ex
sed -i 's/where: w._clinic_id == \^_clinic_id/where: w.clinic_id == ^clinic_id/g' lib/clinicpro_web/controllers/paystack_admin_controller.ex

# Fix PaystackWebhookController
echo "Fixing PaystackWebhookController..."
sed -i 's/Paystack.process_webhook(payload, _clinic_id, conn.assigns\[:request_signature\])/Paystack.process_webhook(payload, clinic_id, conn.assigns[:request_signature])/g' lib/clinicpro_web/controllers/paystack_webhook_controller.ex
sed -i 's/for _clinic_id: #{_clinic_id}/for clinic_id: #{clinic_id}/g' lib/clinicpro_web/controllers/paystack_webhook_controller.ex
sed -i 's/"_clinic_id" => _clinic_id/"clinic_id" => clinic_id/g' lib/clinicpro_web/controllers/paystack_webhook_controller.ex
sed -i 's/when is_integer(_clinic_id), do: _clinic_id/when is_integer(clinic_id), do: clinic_id/g' lib/clinicpro_web/controllers/paystack_webhook_controller.ex
sed -i 's/when is_binary(_clinic_id)/when is_binary(clinic_id)/g' lib/clinicpro_web/controllers/paystack_webhook_controller.ex
sed -i 's/Integer.parse(_clinic_id)/Integer.parse(clinic_id)/g' lib/clinicpro_web/controllers/paystack_webhook_controller.ex
sed -i 's/{:ok, _clinic_id} -> _clinic_id/{:ok, clinic_id} -> clinic_id/g' lib/clinicpro_web/controllers/paystack_webhook_controller.ex

# Fix EnsurePatientAuth
echo "Fixing EnsurePatientAuth..."
sed -i 's/def init(_opts), do: _opts/def init(opts), do: opts/g' lib/clinicpro_web/plugs/ensure_patient_auth.ex
sed -i 's/assign(:current_clinic_id, _clinic_id)/assign(:current_clinic_id, clinic_id)/g' lib/clinicpro_web/plugs/ensure_patient_auth.ex

# Fix WorkflowValidator
echo "Fixing WorkflowValidator..."
sed -i 's/def init(_opts) do/def init(opts) do/g' lib/clinicpro_web/plugs/workflow_validator.ex
sed -i 's/def call(conn, _opts) do/def call(conn, opts) do/g' lib/clinicpro_web/plugs/workflow_validator.ex

# Fix ErrorHelpers
echo "Fixing ErrorHelpers..."
sed -i 's/def translate_error({msg, _opts}) do/def translate_error({msg, opts}) do/g' lib/clinicpro_web/views/error_helpers.ex

echo "✅ All warnings fixed!"
echo "Testing compilation..."

# Test compilation
if mix compile --warnings-as-errors; then
    echo "✅ Compilation successful!"
else
    echo "❌ Still have compilation issues. Manual intervention needed."
    exit 1
fi
