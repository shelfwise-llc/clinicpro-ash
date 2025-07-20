defmodule Clinicpro.Prescriptions do
  use Ash.Api

  resources do
    resource Clinicpro.Prescriptions.Prescription
  end
end
