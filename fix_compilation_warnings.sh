#!/bin/bash

# Fix compilation warnings for ClinicPro
echo "🔧 Fixing compilation warnings..."

# Fix underscored variables that are actually used
echo "Fixing underscored variables..."

# Fix SearchController
sed -i 's/_page: _page,/page: page,/g' lib/clinicpro_web/controllers/search_controller.ex
sed -i 's/(_page - 1)/(page - 1)/g' lib/clinicpro_web/controllers/search_controller.ex
sed -i 's/_page \* 10/page * 10/g' lib/clinicpro_web/controllers/search_controller.ex
sed -i 's/page = _page/page = page/g' lib/clinicpro_web/controllers/search_controller.ex

# Fix EnsurePatientAuth plug
sed -i 's/_opts), do: _opts/opts), do: opts/g' lib/clinicpro_web/plugs/ensure_patient_auth.ex
sed -i 's/_clinic_id)/clinic_id)/g' lib/clinicpro_web/plugs/ensure_patient_auth.ex

# Fix WorkflowValidator plug
sed -i 's/workflow: _opts\[:workflow\]/workflow: opts[:workflow]/g' lib/clinicpro_web/plugs/workflow_validator.ex
sed -i 's/required_step: _opts\[:required_step\]/required_step: opts[:required_step]/g' lib/clinicpro_web/plugs/workflow_validator.ex
sed -i 's/redirect_to: _opts\[:redirect_to\]/redirect_to: opts[:redirect_to]/g' lib/clinicpro_web/plugs/workflow_validator.ex
sed -i 's/init_workflow_state(_opts\[:workflow\])/init_workflow_state(opts[:workflow])/g' lib/clinicpro_web/plugs/workflow_validator.ex
sed -i 's/if _opts\[:required_step\]/if opts[:required_step]/g' lib/clinicpro_web/plugs/workflow_validator.ex
sed -i 's/!= _opts\[:required_step\]/!= opts[:required_step]/g' lib/clinicpro_web/plugs/workflow_validator.ex
sed -i 's/to: _opts\[:redirect_to\]/to: opts[:redirect_to]/g' lib/clinicpro_web/plugs/workflow_validator.ex

# Fix ErrorHelpers
sed -i 's/count = _opts\[:count\]/count = opts[:count]/g' lib/clinicpro_web/views/error_helpers.ex
sed -i 's/, _opts)/, opts)/g' lib/clinicpro_web/views/error_helpers.ex

# Remove unused aliases
echo "Removing unused aliases..."

# Remove unused WorkflowValidator alias
sed -i '/alias ClinicproWeb.Plugs.WorkflowValidator/d' lib/clinicpro_web/controllers/patient_flow_controller/medical_records.ex

# Remove unused Callback alias
sed -i '/alias Clinicpro.Paystack.Callback/d' lib/clinicpro_web/controllers/paystack_webhook_controller.ex

# Remove unused PaystackAdminHTML alias
sed -i '/alias ClinicproWeb.PaystackAdminHTML/d' lib/clinicpro_web/controllers/paystack_admin_controller.ex

echo "✅ Compilation warnings fixed!"
echo "Testing compilation..."

# Test compilation
if mix compile --warnings-as-errors; then
    echo "✅ Compilation successful!"
else
    echo "❌ Still have compilation issues. Check the output above."
    exit 1
fi
