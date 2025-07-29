#!/bin/bash

# Fix function name issues in payment_processor.ex

# Fix appointment function names
sed -i 's/Clinicpro.Appointments.getappointment!/Clinicpro.Appointments.get_appointment!/g' lib/clinicpro/invoices/payment_processor.ex
sed -i 's/Clinicpro.Appointments.updateappointment/Clinicpro.Appointments.update_appointment/g' lib/clinicpro/invoices/payment_processor.ex

# Fix Appointment.get function
sed -i 's/appointment = Appointment.get(invoice.appointment_id)/appointment = Clinicpro.Appointments.Appointment.get_appointment(invoice.appointment_id)/g' lib/clinicpro/invoices/payment_processor.ex

# Fix Clinics.get_clinic function
sed -i 's/clinic = Clinics.get_clinic(get_clinic_id_fromappointment(appointment))/clinic = Clinicpro.Clinics.get_by_id(get_clinic_id_fromappointment(appointment))/g' lib/clinicpro/invoices/payment_processor.ex

# Make the script executable
chmod +x "$0"

echo "Fixed function name issues in payment_processor.ex"
