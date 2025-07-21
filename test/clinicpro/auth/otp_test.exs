defmodule Clinicpro.Auth.OTPTest do
  use Clinicpro.DataCase

  alias Clinicpro.Auth.OTP
  alias Clinicpro.Auth.OTPSecret
  alias Clinicpro.Patient
  alias Clinicpro.Clinic
  alias Clinicpro.Repo

  describe "OTP multi-tenant authentication" do
    setup do
      # Create two test clinics
      {:ok, clinic1} =
        %Clinic{
          name: "Test Clinic 1",
          email: "clinic1@example.com",
          phone_number: "1234567890"
        }
        |> Repo.insert()

      {:ok, clinic2} =
        %Clinic{
          name: "Test Clinic 2",
          email: "clinic2@example.com",
          phone_number: "0987654321"
        }
        |> Repo.insert()

      # Create test patients for each clinic
      {:ok, patient1} =
        %Patient{
          first_name: "John",
          last_name: "Doe",
          email: "john@example.com",
          phone_number: "1111111111",
          clinic_id: clinic1.id
        }
        |> Repo.insert()

      {:ok, patient2} =
        %Patient{
          first_name: "Jane",
          last_name: "Smith",
          email: "jane@example.com",
          phone_number: "2222222222",
          clinic_id: clinic2.id
        }
        |> Repo.insert()

      %{
        clinic1: clinic1,
        clinic2: clinic2,
        patient1: patient1,
        patient2: patient2
      }
    end

    test "generate_otp creates a new OTP secret for a patient in a clinic", %{
      patient1: patient1,
      clinic1: clinic1
    } do
      assert {:ok, %{otp: otp, secret: secret}} = OTP.generate_otp(patient1.id, clinic1.id)
      assert is_binary(otp)
      assert String.length(otp) == 6
      assert secret.patient_id == patient1.id
      assert secret.clinic_id == clinic1.id
      assert secret.active == true
    end

    test "generate_otp deactivates previous OTP secrets", %{
      patient1: patient1,
      clinic1: clinic1
    } do
      # Generate first OTP
      {:ok, %{secret: secret1}} = OTP.generate_otp(patient1.id, clinic1.id)

      # Generate second OTP
      {:ok, %{secret: secret2}} = OTP.generate_otp(patient1.id, clinic1.id)

      # Reload first secret from DB
      updated_secret1 = Repo.get(OTPSecret, secret1.id)

      # First secret should be deactivated
      assert updated_secret1.active == false

      # Second secret should be active
      assert secret2.active == true
    end

    test "validate_otp validates a correct OTP", %{
      patient1: patient1,
      clinic1: clinic1
    } do
      # Generate OTP
      {:ok, %{otp: otp, secret: secret}} = OTP.generate_otp(patient1.id, clinic1.id)

      # Validate the OTP
      assert {:ok, validated_secret} = OTP.validate_otp(patient1.id, clinic1.id, otp)
      assert validated_secret.id == secret.id
    end

    test "validate_otp rejects an incorrect OTP", %{
      patient1: patient1,
      clinic1: clinic1
    } do
      # Generate OTP
      {:ok, _} = OTP.generate_otp(patient1.id, clinic1.id)

      # Try to validate with incorrect OTP
      assert {:error, :invalid_otp} = OTP.validate_otp(patient1.id, clinic1.id, "000000")
    end

    test "OTP secrets are isolated between clinics", %{
      patient1: patient1,
      clinic1: clinic1,
      clinic2: clinic2
    } do
      # Generate OTP for patient1 in clinic1
      {:ok, %{otp: otp1}} = OTP.generate_otp(patient1.id, clinic1.id)

      # Generate OTP for the same patient in clinic2
      {:ok, %{otp: _otp2}} = OTP.generate_otp(patient1.id, clinic2.id)

      # OTP from clinic1 should not work for clinic2
      assert {:error, :invalid_otp} = OTP.validate_otp(patient1.id, clinic2.id, otp1)
    end

    test "OTP secrets are isolated between patients", %{
      patient1: patient1,
      patient2: patient2,
      clinic1: clinic1
    } do
      # Generate OTP for patient1 in clinic1
      {:ok, %{otp: otp1}} = OTP.generate_otp(patient1.id, clinic1.id)

      # Generate OTP for patient2 in the same clinic
      {:ok, %{otp: _otp2}} = OTP.generate_otp(patient2.id, clinic1.id)

      # OTP from patient1 should not work for patient2
      assert {:error, :invalid_otp} = OTP.validate_otp(patient2.id, clinic1.id, otp1)
    end

    test "send_otp delivers OTP via preferred contact method", %{
      patient1: patient1,
      clinic1: clinic1
    } do
      # This test is a bit tricky since we're not actually sending SMS/emails
      # We'll just verify that the function returns the expected structure
      assert {:ok, %{otp: otp, contact: contact, method: method}} =
        OTP.send_otp(patient1.id, clinic1.id)

      assert is_binary(otp)
      assert String.length(otp) == 6
      assert is_binary(contact)
      assert method in [:sms, :email]
    end

    test "generate_qr_code_url creates a valid otpauth URI", %{
      patient1: patient1,
      clinic1: clinic1
    } do
      # First generate an OTP secret
      {:ok, _} = OTP.generate_otp(patient1.id, clinic1.id)

      # Generate QR code URL
      assert {:ok, uri} = OTP.generate_qr_code_url(patient1.id, clinic1.id)

      # Verify it's a valid otpauth URI
      assert String.starts_with?(uri, "otpauth://totp/")
      assert String.contains?(uri, "ClinicPro-#{clinic1.name}")
      assert String.contains?(uri, patient1.email)
    end
  end
end
