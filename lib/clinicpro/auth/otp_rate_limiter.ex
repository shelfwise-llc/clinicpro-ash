defmodule Clinicpro.Auth.OTPRateLimiter do
  @moduledoc """
  Handles rate limiting for OTP generation and verification attempts.
  Prevents abuse by limiting the number of attempts per hour.
  """

  alias Clinicpro.Auth.OTPConfig

  # Use ETS for in-memory tracking of attempts
  @table_name :otp_attempts

  @doc """
  Initializes the OTP rate limiter.
  Should be called when the application starts.
  """
  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
    :ok
  end

  @doc """
  Checks if a patient is allowed to request or verify an OTP.
  Returns :ok if allowed, or {:error, reason} if rate limited.
  """
  def check_rate_limit(patient_id, clinic_identifier) do
    with {:ok, config} <- OTPConfig.get_config_for_clinic(clinic_identifier),
         :ok <- check_attempts(patient_id, clinic_identifier, config) do
      :ok
    else
      error -> error
    end
  end

  @doc """
  Records an OTP attempt for a patient.
  Should be called whenever an OTP is generated or verified.
  """
  def record_attempt(patient_id, clinic_identifier) do
    key = attempt_key(patient_id, clinic_identifier)
    current_time = DateTime.utc_now()

    # Get existing attempts or initialize empty list
    attempts =
      case :ets.lookup(@table_name, key) do
        [{^key, existing_attempts}] -> existing_attempts
        [] -> []
      end

    # Add current attempt and filter out attempts older than 1 hour
    one_hour_ago = DateTime.add(current_time, -3600, :second)
    updated_attempts =
      [current_time | attempts]
      |> Enum.filter(fn time -> DateTime.compare(time, one_hour_ago) in [:gt, :eq] end)

    :ets.insert(@table_name, {key, updated_attempts})
    :ok
  end

  @doc """
  Resets the rate limit for a patient.
  Useful after successful authentication or for administrative purposes.
  """
  def reset_attempts(patient_id, clinic_identifier) do
    key = attempt_key(patient_id, clinic_identifier)
    :ets.delete(@table_name, key)
    :ok
  end

  # Private functions

  defp check_attempts(patient_id, clinic_identifier, config) do
    key = attempt_key(patient_id, clinic_identifier)
    current_time = DateTime.utc_now()

    # Get existing attempts or initialize empty list
    attempts =
      case :ets.lookup(@table_name, key) do
        [{^key, existing_attempts}] -> existing_attempts
        [] -> []
      end

    # Filter attempts to only include those within the last hour
    one_hour_ago = DateTime.add(current_time, -3600, :second)
    recent_attempts =
      attempts
      |> Enum.filter(fn time -> DateTime.compare(time, one_hour_ago) in [:gt, :eq] end)

    # Check if the number of attempts exceeds the limit
    if length(recent_attempts) >= config.max_attempts_per_hour do
      # Calculate time until unlock
      newest_attempt = Enum.max_by(recent_attempts, &DateTime.to_unix/1, fn -> one_hour_ago end)
      unlock_time = DateTime.add(newest_attempt, 3600, :second)
      seconds_remaining = DateTime.diff(unlock_time, current_time)
      minutes_remaining = div(seconds_remaining, 60) + 1

      {:error, {:rate_limited, minutes_remaining}}
    else
      :ok
    end
  end

  defp attempt_key(patient_id, clinic_identifier) do
    "#{patient_id}:#{clinic_identifier}"
  end
end
