defmodule Clinicpro.Auth.OTPDelivery do
  @moduledoc """
  Handles the delivery of OTP codes to patients via SMS and email.
  Supports multi-tenant configuration for different clinics.
  """

  alias Clinicpro.Repo
  alias Clinicpro.Patient
  alias Clinicpro.Clinic

  @doc """
  Sends an OTP to a patient via their preferred contact method (SMS or email).
  Returns {:ok, contact_method} on success or {:error, reason} on failure.
  """
  def send_otp(patient_id, clinic_id, otp) do
    with {:ok, patient} <- get_patient(patient_id),
         {:ok, clinic} <- get_clinic(clinic_id),
         {:ok, delivery_method} <- determine_delivery_method(patient),
         {:ok, config} <- get_delivery_config(clinic, delivery_method) do

      case delivery_method do
        :sms -> send_sms(patient, clinic, otp, config)
        :email -> send_email(patient, clinic, otp, config)
      end
    else
      error -> error
    end
  end

  @doc """
  Determines the best delivery method based on patient contact information.
  Prefers SMS if a valid phone number is available, falls back to email.
  """
  def determine_delivery_method(patient) do
    cond do
      is_valid_phone?(patient.phone_number) ->
        {:ok, :sms}
      is_valid_email?(patient.email) ->
        {:ok, :email}
      true ->
        {:error, :no_valid_contact_method}
    end
  end

  @doc """
  Gets the delivery configuration for a specific clinic and method.
  This follows the same pattern as the M-Pesa configuration management.
  """
  def get_delivery_config(clinic, method) do
    # In a real implementation, this would fetch configuration from the database
    # For now, we'll return a mock configuration based on the clinic
    config = case method do
      :sms ->
        %{
          provider: get_sms_provider(clinic),
          sender_id: clinic.name || "ClinicPro",
          api_key: get_sms_api_key(clinic),
          enabled: true
        }

      :email ->
        %{
          provider: get_email_provider(clinic),
          from_email: "noreply@#{String.downcase(String.replace(clinic.name || "clinicpro", " ", ""))}.com",
          api_key: get_email_api_key(clinic),
          enabled: true
        }
    end

    {:ok, config}
  end

  # Private functions

  defp get_patient(patient_id) do
    case Repo.get(Patient, patient_id) do
      nil -> {:error, :patient_not_found}
      patient -> {:ok, patient}
    end
  end

  defp get_clinic(clinic_id) do
    case Repo.get(Clinic, clinic_id) do
      nil -> {:error, :clinic_not_found}
      clinic -> {:ok, clinic}
    end
  end

  defp is_valid_phone?(nil), do: false
  defp is_valid_phone?(""), do: false
  defp is_valid_phone?(phone) do
    # Basic validation - can be enhanced with proper phone validation
    String.length(String.trim(phone)) >= 10
  end

  defp is_valid_email?(nil), do: false
  defp is_valid_email?(""), do: false
  defp is_valid_email?(email) do
    # Basic email validation - can be enhanced with proper email validation
    String.contains?(email, "@") && String.contains?(email, ".")
  end

  defp send_sms(patient, clinic, otp, config) do
    # In production, integrate with actual SMS provider like Twilio, AfricasTalking, etc.
    # For now, we'll just log the message
    message = "Your #{clinic.name} verification code is: #{otp}"

    # Log the SMS for development
    IO.puts("DEVELOPMENT: SMS to #{patient.phone_number} via #{config.provider}: #{message}")

    # Here you would make the actual API call to your SMS provider
    # Example with a hypothetical SMS service:
    # response = SMSProvider.send_message(
    #   to: patient.phone_number,
    #   message: message,
    #   from: config.sender_id,
    #   api_key: config.api_key
    # )

    # For now, we'll simulate success
    {:ok, %{method: :sms, contact: patient.phone_number}}
  end

  defp send_email(patient, clinic, otp, config) do
    # In production, integrate with actual email provider like SendGrid, Mailgun, etc.
    # For now, we'll just log the message
    subject = "Your #{clinic.name} Verification Code"
    body = """
    Hello #{patient.first_name || "Patient"},

    Your verification code for #{clinic.name} is: #{otp}

    This code will expire in 5 minutes.

    Thank you,
    #{clinic.name} Team
    """

    # Log the email for development
    IO.puts("DEVELOPMENT: Email to #{patient.email} via #{config.provider}:")
    IO.puts("From: #{config.from_email}")
    IO.puts("Subject: #{subject}")
    IO.puts("Body: #{body}")

    # Here you would make the actual API call to your email provider
    # Example with a hypothetical email service:
    # response = EmailProvider.send_email(
    #   to: patient.email,
    #   from: config.from_email,
    #   subject: subject,
    #   body: body,
    #   api_key: config.api_key
    # )

    # For now, we'll simulate success
    {:ok, %{method: :email, contact: patient.email}}
  end

  # These functions would typically fetch configuration from a database
  # Similar to how the M-Pesa integration handles configuration

  defp get_sms_provider(clinic) do
    # This would be fetched from the clinic's configuration
    # For now, we'll return a default provider
    "AfricasTalking"
  end

  defp get_sms_api_key(clinic) do
    # This would be fetched from the clinic's configuration
    # For now, we'll return a mock key
    "sms_#{clinic.id}_key"
  end

  defp get_email_provider(clinic) do
    # This would be fetched from the clinic's configuration
    # For now, we'll return a default provider
    "SendGrid"
  end

  defp get_email_api_key(clinic) do
    # This would be fetched from the clinic's configuration
    # For now, we'll return a mock key
    "email_#{clinic.id}_key"
  end
end
