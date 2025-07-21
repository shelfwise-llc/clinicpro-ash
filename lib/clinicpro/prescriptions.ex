defmodule Clinicpro.Prescriptions do
  use Ash.Api

  resources do
    resource Clinicpro.Prescriptions.Prescription
    resource Clinicpro.Appointments.Appointment
    resource Clinicpro.Accounts.User
    resource Clinicpro.Accounts.UserRole
  end
end
