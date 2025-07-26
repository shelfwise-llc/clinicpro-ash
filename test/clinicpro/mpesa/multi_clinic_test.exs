defmodule Clinicpro.MPesaMultiClinicTest do
  @moduledoc """
  Multi-clinic test for the M-Pesa integration.
  This module simulates multiple clinics receiving payments from different patients.
  """

  @doc """
  Run the multi-clinic payment simulation
  """
  def run_simulation do
    IO.puts("=== ClinicPro M-Pesa Multi-Clinic Simulation ===")
    IO.puts("Simulating payments across multiple clinics")
    IO.puts("All tests run in sandbox mode - no real transactions")
    IO.puts("==============================================\n")

    # Create mock clinics
    clinics = create_mock_clinics()

    # Create mock patients
    patients = create_mock_patients()

    # Simulate payments for each clinic
    Enum.each(clinics, fn clinic ->
      IO.puts("\n" <> String.duplicate("=", 50))
      IO.puts("CLINIC: #{clinic.name} (ID: #{clinic.id})")
      IO.puts(String.duplicate("=", 50))

      # Get clinic-specific configuration
      config = get_mock_config(clinic)

      # Simulate payments from random patients to this clinic
      clinic_patients = Enum.take_random(patients, :rand.uniform(3) + 1)

      Enum.each(clinic_patients, fn patient ->
        simulate_patient_payment(clinic, patient, config)
      end)
    end)

    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("Simulation completed successfully!")
    IO.puts("In a real implementation, these transactions would be stored in the database")
    IO.puts("and each clinic would be able to view only their own transactions.")
    IO.puts(String.duplicate("=", 50))
  end

  @doc """
  Simulate a payment from a patient to a clinic
  """
  def simulate_patient_payment(clinic, patient, config) do
    IO.puts("\n" <> String.duplicate("-", 40))
    IO.puts("PATIENT: #{patient.name} (Phone: #{patient.phone})")
    IO.puts(String.duplicate("-", 40))

    # Generate a random amount between 100 and 5000 KES
    amount = :rand.uniform(49) * 100 + 100

    # Create a unique reference for this payment
    reference = "PAY-#{clinic.id}-#{patient.id}-#{:rand.uniform(999_999)}"

    # Description for the transaction
    description =
      "Payment for #{Enum.random(["Consultation", "Lab Test", "Medication", "Surgery", "Follow-up"])}"

    # Display payment details
    IO.puts("Amount: #{amount} KES")
    IO.puts("Reference: #{reference}")
    IO.puts("Description: #{description}")
    IO.puts("Clinic Shortcode: #{config.shortcode}")
    IO.puts("Environment: #{config.environment}")

    IO.puts("\nInitiating STK Push request...")

    # Simulate the STK Push request
    request_body = %{
      "BusinessShortCode" => config.shortcode,
      "Password" => "encoded_password",
      "Timestamp" => "20250721143000",
      "TransactionType" => "CustomerPayBillOnline",
      "Amount" => amount,
      "PartyA" => patient.phone,
      "PartyB" => config.shortcode,
      "PhoneNumber" => patient.phone,
      "CallBackURL" => config.stk_callback_url,
      "AccountReference" => reference,
      "TransactionDesc" => description
    }

    # Simulate a successful response
    checkout_request_id = "ws_CO_#{clinic.id}_unused#{patient.id}_unused#{:rand.uniform(99999)}"
    merchant_request_id = "#{clinic.id}_unused#{patient.id}_unused#{:rand.uniform(99999)}"

    # Create a mock transaction record
    transaction = %{
      id: "txn_#{:rand.uniform(999_999)}",
      clinic_id: clinic.id,
      patient_id: patient.id,
      phone: patient.phone,
      amount: amount,
      reference: reference,
      description: description,
      checkout_request_id: checkout_request_id,
      merchant_request_id: merchant_request_id,
      status: Enum.random(["pending", "completed", "failed"]),
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    # Display transaction details
    IO.puts("\n✅ Payment #{transaction.status}!")
    IO.puts("Transaction ID: #{transaction.id}")
    IO.puts("Checkout Request ID: #{transaction.checkout_request_id}")
    IO.puts("Merchant Request ID: #{transaction.merchant_request_id}")
    IO.puts("Status: #{String.capitalize(transaction.status)}")
    IO.puts("Created at: #{Calendar.strftime(transaction.created_at, "%d %b %Y, %H:%M:%S")}")

    # Return the transaction
    transaction
  end

  @doc """
  Create mock clinics for testing
  """
  def create_mock_clinics do
    [
      %{
        id: "clinic_001",
        name: "Nairobi Central Clinic",
        location: "Nairobi CBD",
        shortcode: "174379"
      },
      %{
        id: "clinic_002",
        name: "Mombasa Health Center",
        location: "Mombasa",
        shortcode: "174380"
      },
      %{
        id: "clinic_003",
        name: "Kisumu Medical Facility",
        location: "Kisumu",
        shortcode: "174381"
      }
    ]
  end

  @doc """
  Create mock patients for testing
  """
  def create_mock_patients do
    [
      %{
        id: "patient_001",
        name: "John Kamau",
        phone: "254713701723"
      },
      %{
        id: "patient_002",
        name: "Mary Wanjiku",
        phone: "254722123456"
      },
      %{
        id: "patient_003",
        name: "Peter Omondi",
        phone: "254733987654"
      },
      %{
        id: "patient_004",
        name: "Sarah Achieng",
        phone: "254712345678"
      },
      %{
        id: "patient_005",
        name: "David Mwangi",
        phone: "254798765432"
      }
    ]
  end

  @doc """
  Get mock configuration for a clinic
  """
  def get_mock_config(clinic) do
    %{
      clinic_id: clinic.id,
      consumer_key: "test_consumer_key_#{clinic.id}",
      consumer_secret: "test_consumer_secret_#{clinic.id}",
      passkey: "test_passkey_#{clinic.id}",
      shortcode: clinic.shortcode,
      c2b_shortcode: clinic.shortcode,
      stk_callback_url: "https://example.com/clinics/#{clinic.id}/mpesa/stk/callback",
      c2b_validation_url: "https://example.com/clinics/#{clinic.id}/mpesa/c2b/validation",
      c2b_confirmation_url: "https://example.com/clinics/#{clinic.id}/mpesa/c2b/confirmation",
      environment: "sandbox",
      active: true
    }
  end
end

# Run the simulation when this script is executed directly
Clinicpro.MPesaMultiClinicTest.run_simulation()
