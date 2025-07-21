defmodule Clinicpro.Auth.OTPRateLimiterTest do
  use Clinicpro.DataCase

  alias Clinicpro.Auth.OTPRateLimiter
  alias Clinicpro.Auth.OTPConfig
  alias Clinicpro.Patient
  alias Clinicpro.Clinic
  alias Clinicpro.Repo

  setup do
    # Initialize the rate limiter
    OTPRateLimiter.init()

    # Create a test clinic
    {:ok, clinic} =
      %Clinic{
        name: "Test Clinic",
        email: "clinic@example.com",
        phone_number: "1234567890"
      }
      |> Repo.insert()

    # Create a test patient
    {:ok, patient} =
      %Patient{
        first_name: "Test",
        last_name: "Patient",
        email: "patient@example.com",
        phone_number: "9876543210",
        clinic_id: clinic.id
      }
      |> Repo.insert()

    # Create a default OTP config with a low limit for testing
    {:ok, config} =
      %OTPConfig{}
      |> OTPConfig.changeset(%{
        clinic_id: clinic.id,
        max_attempts_per_hour: 3,
        lockout_minutes: 60
      })
      |> Repo.insert()

    %{
      clinic: clinic,
      patient: patient,
      config: config
    }
  end

  describe "OTP rate limiting" do
    test "allows attempts within the limit", %{patient: patient, clinic: clinic} do
      # First attempt
      assert :ok = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)
      OTPRateLimiter.record_attempt(patient.id, clinic.id)

      # Second attempt
      assert :ok = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)
      OTPRateLimiter.record_attempt(patient.id, clinic.id)

      # Third attempt (still within limit)
      assert :ok = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)
      OTPRateLimiter.record_attempt(patient.id, clinic.id)
    end

    test "blocks attempts beyond the limit", %{patient: patient, clinic: clinic} do
      # Make 3 attempts (the limit)
      for _ <- 1..3 do
        assert :ok = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)
        OTPRateLimiter.record_attempt(patient.id, clinic.id)
      end

      # Fourth attempt should be blocked
      assert {:error, {:rate_limited, minutes}} = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)
      assert is_integer(minutes)
      assert minutes > 0
    end

    test "resets attempts successfully", %{patient: patient, clinic: clinic} do
      # Make 3 attempts (the limit)
      for _ <- 1..3 do
        assert :ok = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)
        OTPRateLimiter.record_attempt(patient.id, clinic.id)
      end

      # Should be blocked now
      assert {:error, {:rate_limited, _}} = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)

      # Reset attempts
      OTPRateLimiter.reset_attempts(patient.id, clinic.id)

      # Should be allowed again
      assert :ok = OTPRateLimiter.check_rate_limit(patient.id, clinic.id)
    end

    test "isolates attempts between patients", %{patient: patient1, clinic: clinic} do
      # Create another patient
      {:ok, patient2} =
        %Patient{
          first_name: "Another",
          last_name: "Patient",
          email: "another@example.com",
          phone_number: "5555555555",
          clinic_id: clinic.id
        }
        |> Repo.insert()

      # Make 3 attempts for patient1 (the limit)
      for _ <- 1..3 do
        assert :ok = OTPRateLimiter.check_rate_limit(patient1.id, clinic.id)
        OTPRateLimiter.record_attempt(patient1.id, clinic.id)
      end

      # Patient1 should be blocked
      assert {:error, {:rate_limited, _}} = OTPRateLimiter.check_rate_limit(patient1.id, clinic.id)

      # Patient2 should still be allowed
      assert :ok = OTPRateLimiter.check_rate_limit(patient2.id, clinic.id)
    end

    test "isolates attempts between clinics", %{patient: patient} do
      # Create another clinic
      {:ok, clinic2} =
        %Clinic{
          name: "Another Clinic",
          email: "another@example.com",
          phone_number: "5555555555"
        }
        |> Repo.insert()

      # Create config for the second clinic
      {:ok, _} =
        %OTPConfig{}
        |> OTPConfig.changeset(%{
          clinic_id: clinic2.id,
          max_attempts_per_hour: 3,
          lockout_minutes: 60
        })
        |> Repo.insert()

      # Make 3 attempts for the first clinic (the limit)
      for _ <- 1..3 do
        assert :ok = OTPRateLimiter.check_rate_limit(patient.id, patient.clinic_id)
        OTPRateLimiter.record_attempt(patient.id, patient.clinic_id)
      end

      # First clinic should be blocked
      assert {:error, {:rate_limited, _}} = OTPRateLimiter.check_rate_limit(patient.id, patient.clinic_id)

      # Second clinic should still be allowed
      assert :ok = OTPRateLimiter.check_rate_limit(patient.id, clinic2.id)
    end
  end
end
