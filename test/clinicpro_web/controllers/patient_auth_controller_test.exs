defmodule ClinicproWeb.PatientAuthControllerTest do
  use ClinicproWeb.ConnCase

  alias Clinicpro.Patient
  alias Clinicpro.Clinic
  alias Clinicpro.Auth.OTP
  alias Clinicpro.Auth.OTPConfig
  alias Clinicpro.Auth.OTPRateLimiter
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

    # Create OTP config with low limits for testing
    {:ok, _config} =
      %OTPConfig{}
      |> OTPConfig.changeset(%{
        clinic_id: clinic.id,
        max_attempts_per_hour: 3,
        lockout_minutes: 60,
        delivery_method: "both",
        sms_provider: "africas_talking",
        sms_api_key: "test_key",
        sms_sender_id: "TEST",
        email_provider: "sendgrid",
        email_api_key: "test_key",
        email_sender: "test@example.com"
      })
      |> Repo.insert()

    %{
      clinic: clinic,
      patient: patient,
      conn: Phoenix.ConnTest.build_conn()
    }
  end

  describe "OTP authentication flow" do
    test "request_otp renders the OTP request form", %{conn: conn, clinic: clinic} do
      conn = get(conn, ~p"/patient/request-otp?clinic_id=#{clinic.id}")
      assert html_response(conn, 200) =~ "Request OTP"
    end

    test "send_otp sends an OTP and redirects to verify page", %{conn: conn, clinic: clinic} do
      conn =
        post(conn, ~p"/patient/send-otp?clinic_id=#{clinic.id}", %{
          "patient" => %{
            "phone_number" => "9876543210",
            "email" => "new_patient@example.com"
          }
        })

      assert redirected_to(conn) =~ "/patient/verify-otp"
      assert get_flash(conn, :info) =~ "OTP sent to"
    end

    test "send_otp creates a new patient if not found", %{conn: conn, clinic: clinic} do
      conn =
        post(conn, ~p"/patient/send-otp?clinic_id=#{clinic.id}", %{
          "patient" => %{
            "phone_number" => "1112223333",
            "email" => "new_patient@example.com",
            "first_name" => "New",
            "last_name" => "Patient"
          }
        })

      assert redirected_to(conn) =~ "/patient/verify-otp"
      assert get_flash(conn, :info) =~ "OTP sent to"

      # Verify the patient was created
      patient = Repo.get_by(Patient, phone_number: "1112223333")
      assert patient != nil
      assert patient.first_name == "New"
    end

    test "verify_otp_form renders the OTP verification form", %{
      conn: conn,
      clinic: clinic,
      patient: patient
    } do
      # First send an OTP to set up the session
      conn =
        post(conn, ~p"/patient/send-otp?clinic_id=#{clinic.id}", %{
          "patient" => %{
            "phone_number" => patient.phone_number
          }
        })

      # Then access the verification form
      conn = get(recycle(conn), ~p"/patient/verify-otp?clinic_id=#{clinic.id}")
      assert html_response(conn, 200) =~ "Verify OTP"
    end

    test "verify_otp authenticates with valid OTP", %{
      conn: conn,
      clinic: clinic,
      patient: patient
    } do
      # Generate an OTP for the patient
      {:ok, %{otp: otp}} = OTP.generate_otp(patient.id, clinic.id)

      # Set up the session as if the OTP was requested
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otp_clinic_id, clinic.id)

      # Submit the OTP for verification
      conn = post(conn, ~p"/patient/verify-otp?clinic_id=#{clinic.id}", %{"otp" => otp})

      # Should redirect to dashboard
      assert redirected_to(conn) == "/patient/dashboard"
      assert get_flash(conn, :info) =~ "Successfully authenticated"

      # Session should be updated
      assert get_session(conn, :patient_id) == patient.id
      assert get_session(conn, :clinic_id) == clinic.id
      assert get_session(conn, :pending_otp_patient_id) == nil
    end

    test "verify_otp rejects invalid OTP", %{conn: conn, clinic: clinic, patient: patient} do
      # Set up the session as if the OTP was requested
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otp_clinic_id, clinic.id)

      # Submit an invalid OTP
      conn = post(conn, ~p"/patient/verify-otp?clinic_id=#{clinic.id}", %{"otp" => "999999"})

      # Should redirect back to verify page
      assert redirected_to(conn) =~ "/patient/verify-otp"
      assert get_flash(conn, :error) =~ "Invalid OTP"
    end

    test "dashboard requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/patient/dashboard")
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Please log in"
    end

    test "dashboard shows patient info when authenticated", %{
      conn: conn,
      patient: patient,
      clinic: clinic
    } do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:patient_id, patient.id)
        |> put_session(:clinic_id, clinic.id)

      conn = get(conn, ~p"/patient/dashboard")
      assert html_response(conn, 200) =~ "Dashboard"
      assert html_response(conn, 200) =~ patient.first_name
    end

    test "logout clears the session", %{conn: conn, patient: patient, clinic: clinic} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:patient_id, patient.id)
        |> put_session(:clinic_id, clinic.id)

      conn = get(conn, ~p"/patient/logout")
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "logged out"
      assert get_session(conn, :patient_id) == nil
    end

    test "rate limiting blocks excessive OTP requests", %{
      conn: conn,
      clinic: clinic,
      patient: patient
    } do
      # Make 3 OTP requests (the limit)
      for _unused <- 1..3 do
        conn =
          conn
          |> recycle()
          |> post(~p"/patient/send-otp?clinic_id=#{clinic.id}", %{
            "patient" => %{
              "phone_number" => patient.phone_number
            }
          })

        assert redirected_to(conn) =~ "/patient/verify-otp"
      end

      # Fourth request should be rate limited
      conn =
        conn
        |> recycle()
        |> post(~p"/patient/send-otp?clinic_id=#{clinic.id}", %{
          "patient" => %{
            "phone_number" => patient.phone_number
          }
        })

      assert redirected_to(conn) =~ "/patient/request-otp"
      assert get_flash(conn, :error) =~ "Too many OTP requests"
    end

    test "rate limiting blocks excessive OTP verification attempts", %{
      conn: conn,
      clinic: clinic,
      patient: patient
    } do
      # Generate an OTP for the patient
      {:ok, %{otp: _otp}} = OTP.generate_otp(patient.id, clinic.id)

      # Set up the session as if the OTP was requested
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otp_clinic_id, clinic.id)

      # Make 3 invalid verification attempts (the limit)
      for _unused <- 1..3 do
        conn =
          conn
          |> recycle()
          |> init_test_session(%{})
          |> put_session(:pending_otp_patient_id, patient.id)
          |> put_session(:pending_otp_clinic_id, clinic.id)
          |> post(~p"/patient/verify-otp?clinic_id=#{clinic.id}", %{"otp" => "999999"})

        assert redirected_to(conn) =~ "/patient/verify-otp"
      end

      # Fourth attempt should be rate limited
      conn =
        conn
        |> recycle()
        |> init_test_session(%{})
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otp_clinic_id, clinic.id)
        |> post(~p"/patient/verify-otp?clinic_id=#{clinic.id}", %{"otp" => "999999"})

      assert redirected_to(conn) =~ "/patient/request-otp"
      assert get_flash(conn, :error) =~ "Too many verification attempts"
    end

    test "successful verification resets rate limiting", %{
      conn: conn,
      clinic: clinic,
      patient: patient
    } do
      # Generate an OTP for the patient
      {:ok, %{otp: otp}} = OTP.generate_otp(patient.id, clinic.id)

      # Make 2 invalid verification attempts
      for _unused <- 1..2 do
        conn =
          conn
          |> recycle()
          |> init_test_session(%{})
          |> put_session(:pending_otp_patient_id, patient.id)
          |> put_session(:pending_otp_clinic_id, clinic.id)
          |> post(~p"/patient/verify-otp?clinic_id=#{clinic.id}", %{"otp" => "999999"})
      end

      # Third attempt with correct OTP should succeed and reset rate limiting
      conn =
        conn
        |> recycle()
        |> init_test_session(%{})
        |> put_session(:pending_otp_patient_id, patient.id)
        |> put_session(:pending_otp_clinic_id, clinic.id)
        |> post(~p"/patient/verify-otp?clinic_id=#{clinic.id}", %{"otp" => otp})

      assert redirected_to(conn) == "/patient/dashboard"

      # After successful verification, we should be able to request a new OTP
      # Generate a new patient to avoid session conflicts
      {:ok, new_patient} =
        %Patient{
          first_name: "Another",
          last_name: "Patient",
          email: "another@example.com",
          phone_number: "5555555555",
          clinic_id: clinic.id
        }
        |> Repo.insert()

      # Should be able to make 3 more requests
      for _unused <- 1..3 do
        conn =
          conn
          |> recycle()
          |> post(~p"/patient/send-otp?clinic_id=#{clinic.id}", %{
            "patient" => %{
              "phone_number" => new_patient.phone_number
            }
          })

        assert redirected_to(conn) =~ "/patient/verify-otp"
      end
    end
  end
end
