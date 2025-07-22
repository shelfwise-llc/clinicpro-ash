# Script to simulate M-Pesa callbacks for testing
# Usage: mix run scripts/simulate_mpesa_callback.exs

defmodule Clinicpro.Scripts.SimulateMPesaCallback do
  @moduledoc """
  This script simulates M-Pesa callbacks for testing purposes.
  It allows you to test the callback handling and invoice processing
  without having to rely on actual M-Pesa callbacks.
  """

  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.AdminBypass.{Invoice, Appointment, Patient, Doctor}
  alias Clinicpro.Repo

  def run do
    IO.puts("Starting M-Pesa callback simulation...")
    
    # Create test data
    {:ok, data} = create_test_data()
    
    # Simulate STK Push callback
    simulate_stk_callback(data.virtual_transaction)
    
    # Simulate C2B callback
    simulate_c2b_callback(data.onsite_transaction)
    
    IO.puts("Simulation completed!")
  end

  defp create_test_data do
    IO.puts("Creating test data...")
    
    # Create a clinic (doctor)
    {:ok, clinic} = Doctor.create_doctor(%{
      first_name: "Test",
      last_name: "Clinic",
      email: "clinic@example.com",
      phone: "254700000000",
      specialty: "General",
      license_number: "12345"
    })
    
    # Create a patient
    {:ok, patient} = Patient.create_patient(%{
      first_name: "Test",
      last_name: "Patient",
      email: "patient@example.com",
      phone: "254711111111",
      clinic_id: clinic.id
    })
    
    # Create a virtual appointment
    {:ok, virtual_appointment} = Appointment.create_appointment(%{
      patient_id: patient.id,
      clinic_id: clinic.id,
      appointment_date: Date.utc_today(),
      appointment_time: ~T[10:00:00],
      reason: "Virtual Consultation",
      status: "scheduled",
      appointment_type: "virtual"
    })
    
    # Create an onsite appointment
    {:ok, onsite_appointment} = Appointment.create_appointment(%{
      patient_id: patient.id,
      clinic_id: clinic.id,
      appointment_date: Date.utc_today(),
      appointment_time: ~T[14:00:00],
      reason: "Physical Checkup",
      status: "scheduled",
      appointment_type: "onsite"
    })
    
    # Create invoices for the appointments
    {:ok, virtual_invoice} = Invoice.create_invoice(%{
      patient_id: patient.id,
      clinic_id: clinic.id,
      appointment_id: virtual_appointment.id,
      amount: Decimal.new(1000),
      due_date: Date.utc_today(),
      description: "Virtual Consultation Fee",
      status: "pending",
      payment_reference: "SIM-VIRTUAL-REF-123"
    })
    
    {:ok, onsite_invoice} = Invoice.create_invoice(%{
      patient_id: patient.id,
      clinic_id: clinic.id,
      appointment_id: onsite_appointment.id,
      amount: Decimal.new(1500),
      due_date: Date.utc_today(),
      description: "Physical Checkup Fee",
      status: "pending",
      payment_reference: "SIM-ONSITE-REF-456"
    })
    
    # Create pending transactions for the invoices
    {:ok, virtual_transaction} = Transaction.create_pending(%{
      clinic_id: clinic.id,
      reference: "SIM-VIRTUAL-REF-123",
      phone: "254711111111",
      amount: 1000,
      type: "stk_push",
      description: "Virtual Consultation Fee",
      checkout_request_id: "ws_CO_123456789",
      merchant_request_id: "123-456-789"
    })
    
    {:ok, onsite_transaction} = Transaction.create_pending(%{
      clinic_id: clinic.id,
      reference: "SIM-ONSITE-REF-456",
      phone: "254711111111",
      amount: 1500,
      type: "c2b",
      description: "Physical Checkup Fee"
    })
    
    IO.puts("Test data created successfully!")
    
    {:ok, %{
      clinic: clinic,
      patient: patient,
      virtual_appointment: virtual_appointment,
      onsite_appointment: onsite_appointment,
      virtual_invoice: virtual_invoice,
      onsite_invoice: onsite_invoice,
      virtual_transaction: virtual_transaction,
      onsite_transaction: onsite_transaction
    }}
  end

  defp simulate_stk_callback(transaction) do
    IO.puts("Simulating STK Push callback for transaction #{transaction.id}...")
    
    # Create a mock successful STK Push callback payload
    callback_payload = %{
      "Body" => %{
        "stkCallback" => %{
          "MerchantRequestID" => transaction.merchant_request_id,
          "CheckoutRequestID" => transaction.checkout_request_id,
          "ResultCode" => "0",
          "ResultDesc" => "The service request is processed successfully.",
          "CallbackMetadata" => %{
            "Item" => [
              %{"Name" => "Amount", "Value" => 1000},
              %{"Name" => "MpesaReceiptNumber", "Value" => "SIM1234567"},
              %{"Name" => "TransactionDate", "Value" => 20230601121212},
              %{"Name" => "PhoneNumber", "Value" => "254711111111"}
            ]
          }
        }
      }
    }
    
    # Make HTTP request to the callback endpoint
    url = "http://localhost:4000/api/mpesa/callbacks/stk"
    headers = [{"Content-Type", "application/json"}]
    
    case HTTPoison.post(url, Jason.encode!(callback_payload), headers) do
      {:ok, response} ->
        IO.puts("STK Push callback sent successfully!")
        IO.puts("Response status: #{response.status_code}")
        IO.puts("Response body: #{response.body}")
        
        # Wait a moment for the async task to complete
        :timer.sleep(1000)
        
        # Check if invoice was updated
        check_invoice_status("SIM-VIRTUAL-REF-123")
        
      {:error, error} ->
        IO.puts("Failed to send STK Push callback: #{inspect(error)}")
    end
  end

  defp simulate_c2b_callback(transaction) do
    IO.puts("Simulating C2B callback for transaction #{transaction.id}...")
    
    # Create a mock successful C2B callback payload
    callback_payload = %{
      "TransID" => "SIM7654321",
      "TransAmount" => "1500",
      "BillRefNumber" => transaction.reference,
      "MSISDN" => "254711111111",
      "TransactionType" => "Pay Bill",
      "BusinessShortCode" => "123456"
    }
    
    # Make HTTP request to the callback endpoint
    url = "http://localhost:4000/api/mpesa/callbacks/c2b/confirmation"
    headers = [{"Content-Type", "application/json"}]
    
    case HTTPoison.post(url, Jason.encode!(callback_payload), headers) do
      {:ok, response} ->
        IO.puts("C2B callback sent successfully!")
        IO.puts("Response status: #{response.status_code}")
        IO.puts("Response body: #{response.body}")
        
        # Wait a moment for the async task to complete
        :timer.sleep(1000)
        
        # Check if invoice was updated
        check_invoice_status("SIM-ONSITE-REF-456")
        
      {:error, error} ->
        IO.puts("Failed to send C2B callback: #{inspect(error)}")
    end
  end

  defp check_invoice_status(reference) do
    case Clinicpro.AdminBypass.Invoice.get_invoice_by_reference(reference) do
      nil ->
        IO.puts("Invoice with reference #{reference} not found!")
        
      invoice ->
        IO.puts("Invoice status: #{invoice.status}")
        
        # Check appointment status
        case Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id) do
          nil ->
            IO.puts("Appointment not found!")
            
          appointment ->
            IO.puts("Appointment status: #{appointment.status}")
            IO.puts("Appointment type: #{appointment.appointment_type}")
            
            if appointment.appointment_type == "virtual" do
              IO.puts("Meeting link: #{appointment.meeting_link || "Not generated"}")
            end
        end
    end
  end
end

# Run the simulation
Clinicpro.Scripts.SimulateMPesaCallback.run()
