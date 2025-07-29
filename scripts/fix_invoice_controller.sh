#!/bin/bash

# Fix undefined variable patients in invoice_controller.ex
sed -i 's/_patients: patients,/_patients: _patients,/g' lib/clinicpro_web/controllers/invoice_controller.ex

# Make the script executable
chmod +x "$0"

echo "Fixed undefined variable patients in invoice_controller.ex"
