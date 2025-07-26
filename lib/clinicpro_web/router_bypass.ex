defmodule ClinicproWeb.RouterBypass do
  @moduledoc """
  Router configuration for bypass controllers.

  This module provides router configuration that can be imported into the main router
  to enable the bypass controllers while AshAuthentication issues are being resolved.
  """

  defmacro doctor_flow_bypass_routes do
    quote do
      # Doctor flow routes that bypass AshAuthentication
      scope "/doctor", ClinicproWeb do
        # Removed pipe_through to avoid duplicate pipe_through error

        # List appointments
        get "/appointments", DoctorFlowBypassController, :list_appointments

        # Access _appointment details
        get "/appointments/:id", DoctorFlowBypassController, :access_appointment

        # Medical details
        get "/appointments/:id/medical_details",
            DoctorFlowBypassController,
            :fill_medical_details_form

        post "/appointments/:id/medical_details",
             DoctorFlowBypassController,
             :fill_medical_details

        # Diagnosis
        get "/appointments/:id/diagnosis", DoctorFlowBypassController, :record_diagnosis_form
        post "/appointments/:id/diagnosis", DoctorFlowBypassController, :record_diagnosis

        # Complete _appointment
        get "/appointments/:id/complete", DoctorFlowBypassController, :complete_appointment_form
        post "/appointments/:id/complete", DoctorFlowBypassController, :complete_appointment
      end
    end
  end
end
