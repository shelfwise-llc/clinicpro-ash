defmodule Clinicpro.Integration.MpesaVirtualMeetingsTest do
  use Clinicpro.DataCase

  @moduledoc """
  Integration tests for M-Pesa and Virtual Meetings.

  These tests verify the multi-tenant architecture of the M-Pesa and Virtual Meetings integration,
  ensuring that each clinic can handle payments independently and generate meeting links
  using their configured adapter.
  """

  # Import test helpers
  # import Clinicpro.TestHelpers

  # Define test tags
  @moduletag :integration
  @moduletag :mpesa
  @moduletag :virtual_meetings

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.VirtualMeetings
  alias Clinicpro.VirtualMeetings.Config
  alias Clinicpro.AdminBypass.Appointment
  alias Clinicpro.Clinics.Clinic
  alias Clinicpro.Repo

  # Setup test data
  setup do
    # Create test clinics with different configurations
    {:ok, clinic_a} =
      create_clinic("Clinic A", %{
        mpesa_config: %{
          consumer_key: "clinic_a_key",
          consumer_secret: "clinic_a_secret",
          passkey: "clinic_a_passkey",
          shortcode: "clinic_a_shortcode"
        },
        virtual_meeting_config: %{
          adapter: "Clinicpro.VirtualMeetings.GoogleMeetAdapter",
          google_api_credentials: %{
            json: System.get_env("GOOGLE_API_CREDENTIALS_JSON")
          },
          calendar_id: "primary"
        }
      })

    {:ok, clinic_b} =
      create_clinic("Clinic B", %{
        mpesa_config: %{
          consumer_key: "clinic_b_key",
          consumer_secret: "clinic_b_secret",
          passkey: "clinic_b_passkey",
          shortcode: "clinic_b_shortcode"
        },
        virtual_meeting_config: %{
          adapter: "Clinicpro.VirtualMeetings.ZoomAdapter",
          zoom_api_credentials: %{
            client_id: System.get_env("ZOOM_CLIENT_ID"),
            client_secret: System.get_env("ZOOM_CLIENT_SECRET")
          }
        }
      })

    {:ok, clinic_c} =
      create_clinic("Clinic C", %{
        mpesa_config: %{
          consumer_key: "clinic_c_key",
          consumer_secret: "clinic_c_secret",
          passkey: "clinic_c_passkey",
          shortcode: "clinic_c_shortcode"
        },
        virtual_meeting_config: %{
          adapter: "Clinicpro.VirtualMeetings.ZoomAdapter",
          zoom_api_credentials: %{
            api_key: System.get_env("ZOOM_API_KEY"),
            api_secret: System.get_env("ZOOM_API_SECRET")
          }
        }
      })

    {:ok, clinic_d} =
      create_clinic("Clinic D", %{
        mpesa_config: %{
          consumer_key: "clinic_d_key",
          consumer_secret: "clinic_d_secret",
          passkey: "clinic_d_passkey",
          shortcode: "clinic_d_shortcode"
        },
        virtual_meeting_config: %{
          adapter: "Clinicpro.VirtualMeetings.SimpleAdapter"
        }
      })

    # Create test appointments
    appointment_a = create_appointment(clinic_a.id, "virtual")
    appointment_b = create_appointment(clinic_b.id, "virtual")
    appointment_c = create_appointment(clinic_c.id, "virtual")
    appointment_d = create_appointment(clinic_d.id, "virtual")

    # Return test data
    %{
      clinics: %{
        a: clinic_a,
        b: clinic_b,
        c: clinic_c,
        d: clinic_d
      },
      appointments: %{
        a: appointment_a,
        b: appointment_b,
        c: appointment_c,
        d: appointment_d
      }
    }
  end

  # Test cases for M-Pesa multi-tenant functionality
  describe "M-Pesa multi-tenant tests" do
    @tag :mpesa_config
    test "each clinic has its own M-Pesa configuration", %{clinics: clinics} do
      # Verify clinic A config
      {:ok, config_a} = MPesa.get_clinic_config(clinics.a.id)
      assert config_a.consumer_key == "clinic_a_key"
      assert config_a.consumer_secret == "clinic_a_secret"
      assert config_a.passkey == "clinic_a_passkey"
      assert config_a.shortcode == "clinic_a_shortcode"

      # Verify clinic B config
      {:ok, config_b} = MPesa.get_clinic_config(clinics.b.id)
      assert config_b.consumer_key == "clinic_b_key"
      assert config_b.consumer_secret == "clinic_b_secret"
      assert config_b.passkey == "clinic_b_passkey"
      assert config_b.shortcode == "clinic_b_shortcode"

      # Verify configs are different
      refute config_a == config_b
    end

    @tag :transaction_isolation
    test "transactions are isolated by clinic", %{clinics: clinics} do
      # Create transactions for different clinics
      {:ok, transaction_a} =
        MPesa.create_transaction(%{
          clinic_id: clinics.a.id,
          amount: 1000,
          phone_number: "254712345678",
          reference: "REF-A-123",
          description: "Test payment for Clinic A"
        })

      {:ok, transaction_b} =
        MPesa.create_transaction(%{
          clinic_id: clinics.b.id,
          amount: 2000,
          phone_number: "254723456789",
          reference: "REF-B-456",
          description: "Test payment for Clinic B"
        })

      # Verify transactions are associated with correct clinics
      assert transaction_a.clinic_id == clinics.a.id
      assert transaction_b.clinic_id == clinics.b.id

      # Verify clinic A can only see its own transactions
      clinic_a_transactions = MPesa.list_clinic_transactions(clinics.a.id)
      assert length(clinic_a_transactions) == 1
      assert Enum.at(clinic_a_transactions, 0).id == transaction_a.id

      # Verify clinic B can only see its own transactions
      clinic_b_transactions = MPesa.list_clinic_transactions(clinics.b.id)
      assert length(clinic_b_transactions) == 1
      assert Enum.at(clinic_b_transactions, 0).id == transaction_b.id
    end
  end

  # Test cases for virtual meetings integration
  describe "Virtual meetings integration tests" do
    @tag :virtual_meetings
    @tag :external_api
    test "M-Pesa payment triggers meeting creation with correct adapter", %{
      clinics: clinics,
      appointments: appointments
    } do
      # Simulate M-Pesa payment for clinic A (Google Meet)
      {:ok, transaction_a} =
        MPesa.create_transaction(%{
          clinic_id: clinics.a.id,
          amount: appointments.a.amount,
          phone_number: "254712345678",
          reference: appointments.a.reference,
          description: "Payment for appointment #{appointments.a.id}"
        })

      # Process payment callback
      {:ok, _unused} =
        MPesa.process_payment_callback(
          %{
            "ResultCode" => "0",
            "ResultDesc" => "Success",
            "MerchantRequestID" => transaction_a.merchant_request_id,
            "CheckoutRequestID" => transaction_a.checkout_request_id,
            "Amount" => transaction_a.amount,
            "MpesaReceiptNumber" => "LHG31AA5TX",
            "TransactionDate" => "20250722173000",
            "PhoneNumber" => transaction_a.phone_number
          },
          clinics.a.id
        )

      # Verify appointment has been updated with meeting link
      updated_appointment_a = Repo.get(Appointment, appointments.a.id)
      assert updated_appointment_a.meeting_url != nil
      assert updated_appointment_a.meeting_provider == "google_meet"

      # Simulate M-Pesa payment for clinic B (Zoom OAuth)
      {:ok, transaction_b} =
        MPesa.create_transaction(%{
          clinic_id: clinics.b.id,
          amount: appointments.b.amount,
          phone_number: "254723456789",
          reference: appointments.b.reference,
          description: "Payment for appointment #{appointments.b.id}"
        })

      # Process payment callback
      {:ok, _unused} =
        MPesa.process_payment_callback(
          %{
            "ResultCode" => "0",
            "ResultDesc" => "Success",
            "MerchantRequestID" => transaction_b.merchant_request_id,
            "CheckoutRequestID" => transaction_b.checkout_request_id,
            "Amount" => transaction_b.amount,
            "MpesaReceiptNumber" => "LHG31AA5TY",
            "TransactionDate" => "20250722173100",
            "PhoneNumber" => transaction_b.phone_number
          },
          clinics.b.id
        )

      # Verify appointment has been updated with meeting link
      updated_appointment_b = Repo.get(Appointment, appointments.b.id)
      assert updated_appointment_b.meeting_url != nil
      assert updated_appointment_b.meeting_provider == "zoom"
    end

    @tag :fallback
    test "system falls back to SimpleAdapter when API fails", %{
      clinics: clinics,
      appointments: appointments
    } do
      # Override clinic A config to use invalid credentials
      {:ok, _unused} =
        Config.set_clinic_config(clinics.a.id, %{
          adapter: "Clinicpro.VirtualMeetings.GoogleMeetAdapter",
          google_api_credentials: %{
            json: "{\"invalid\": \"credentials\"}"
          }
        })

      # Simulate M-Pesa payment for clinic A
      {:ok, transaction_a} =
        MPesa.create_transaction(%{
          clinic_id: clinics.a.id,
          amount: appointments.a.amount,
          phone_number: "254712345678",
          reference: appointments.a.reference,
          description: "Payment for appointment #{appointments.a.id}"
        })

      # Process payment callback
      {:ok, _unused} =
        MPesa.process_payment_callback(
          %{
            "ResultCode" => "0",
            "ResultDesc" => "Success",
            "MerchantRequestID" => transaction_a.merchant_request_id,
            "CheckoutRequestID" => transaction_a.checkout_request_id,
            "Amount" => transaction_a.amount,
            "MpesaReceiptNumber" => "LHG31AA5TZ",
            "TransactionDate" => "20250722173200",
            "PhoneNumber" => transaction_a.phone_number
          },
          clinics.a.id
        )

      # Verify appointment has been updated with SimpleAdapter meeting link
      updated_appointment_a = Repo.get(Appointment, appointments.a.id)
      assert updated_appointment_a.meeting_url != nil
      assert updated_appointment_a.meeting_provider == "simple"
    end
  end

  # Test cases for multi-tenant configuration
  describe "Multi-tenant configuration tests" do
    @tag :config
    test "each clinic can have different virtual meeting adapters", %{clinics: clinics} do
      # Verify clinic A uses Google Meet adapter
      {:ok, config_a} = Config.get_clinic_config(clinics.a.id)
      assert config_a.adapter == "Clinicpro.VirtualMeetings.GoogleMeetAdapter"

      # Verify clinic B uses Zoom adapter
      {:ok, config_b} = Config.get_clinic_config(clinics.b.id)
      assert config_b.adapter == "Clinicpro.VirtualMeetings.ZoomAdapter"

      # Verify clinic D uses SimpleAdapter
      {:ok, config_d} = Config.get_clinic_config(clinics.d.id)
      assert config_d.adapter == "Clinicpro.VirtualMeetings.SimpleAdapter"
    end

    @tag :runtime_config
    test "adapter can be changed at runtime", %{clinics: clinics} do
      # Change clinic A adapter to Zoom
      {:ok, _unused} =
        Config.set_clinic_adapter(clinics.a.id, Clinicpro.VirtualMeetings.ZoomAdapter)

      # Verify adapter was changed
      {:ok, updated_config} = Config.get_clinic_config(clinics.a.id)
      assert updated_config.adapter == "Clinicpro.VirtualMeetings.ZoomAdapter"
    end
  end

  # Helper functions for testing

  defp create_clinic(name, config) do
    Repo.insert(%Clinic{
      name: name,
      mpesa_config: config.mpesa_config,
      virtual_meeting_config: config.virtual_meeting_config
    })
  end

  defp create_appointment(clinic_id, type) do
    appointment = %Appointment{
      clinic_id: clinic_id,
      patient_id: Ecto.UUID.generate(),
      doctor_id: Ecto.UUID.generate(),
      appointment_date: Date.utc_today(),
      appointment_time: ~T[10:00:00],
      duration: 30,
      type: type,
      status: "pending_payment",
      amount: 1000,
      reference: "APP-#{Ecto.UUID.generate()}",
      meeting_url: nil,
      meeting_provider: nil
    }

    Repo.insert!(appointment)
  end
end
