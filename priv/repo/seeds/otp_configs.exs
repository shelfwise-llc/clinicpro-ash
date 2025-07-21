# Script for populating the database with default OTP configurations.
# Run with `mix run priv/repo/seeds/otp_configs.exs`

alias Clinicpro.Repo
alias Clinicpro.Clinic
alias Clinicpro.Auth.OTPConfig

# Get all clinic settings to create OTP configs for each clinic identifier
clinic_settings = Repo.all(Clinicpro.ClinicSetting)

# Extract unique clinic identifiers
clinic_identifiers = 
  clinic_settings
  |> Enum.map(fn setting -> setting.clinic_identifier end)
  |> Enum.uniq()

# Filter out clinic identifiers that already have OTP configs
clinic_identifiers_without_configs =
  clinic_identifiers
  |> Enum.filter(fn identifier ->
    case OTPConfig.get_config_for_clinic(identifier) do
      {:ok, _config} -> false
      {:error, _} -> true
    end
  end)

# Create default OTP configs for each clinic identifier
for identifier <- clinic_identifiers_without_configs do
  %OTPConfig{}
  |> OTPConfig.changeset(%{
    clinic_identifier: identifier,
    preferred_method: "sms",
    max_attempts_per_hour: 5,
    lockout_minutes: 30,
    sms_provider: "AfricasTalking",
    sms_api_key: "default_key_#{identifier}",
    sms_sender_id: identifier |> String.slice(0, 10),
    sms_enabled: true,
    email_provider: "SendGrid",
    email_api_key: "default_key_#{identifier}",
    email_from_address: "no-reply@#{String.downcase(identifier |> String.replace(" ", "-"))}.clinicpro.com",
    email_enabled: true,
    otp_expiry_minutes: 5
  })
  |> Repo.insert!()

  IO.puts("Created default OTP config for clinic identifier: #{identifier}")
end

if Enum.empty?(clinic_identifiers_without_configs) do
  IO.puts("All clinic identifiers already have OTP configurations.")
else
  IO.puts("Created #{length(clinic_identifiers_without_configs)} OTP configurations.")
end
