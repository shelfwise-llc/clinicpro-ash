defmodule Clinicpro.MPesa.CallbackInvoiceTest do
  @moduledoc """
  Tests for M-Pesa callback handling and invoice status updates.
  
  This test module verifies that invoice status is properly updated when
  M-Pesa payment callbacks are received, and that appropriate actions are
  taken based on the appointment type.
  """
  
  use Clinicpro.DataCase
  
  alias Clinicpro.MPesa.{Callback, Transaction}
  alias Clinicpro.AdminBypass.{Invoice, Patient, Doctor, Appointment}
  alias Clinicpro.Invoices
  
  describe "STK Push callbacks" do
    setup do
      # Create a clinic (doctor)
      {:ok, clinic} = Doctor.create_doctor(%{
        name: "Test Clinic",
        email: "clinic@example.com",
        phone: "254700000000",
        specialty: "General",
        license_number: "12345"
      })
      
      # Create a patient
      {:ok, patient} = Patient.create_patient(%{
        name: "Test Patient",
        email: "patient@example.com",
        phone: "254711111111",
        clinic_id: clinic.id
      })
      
      # Create an appointment
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
        payment_reference: "TEST-VIRTUAL-REF-123"
      })
      
      {:ok, onsite_invoice} = Invoice.create_invoice(%{
        patient_id: patient.id,
        clinic_id: clinic.id,
        appointment_id: onsite_appointment.id,
        amount: Decimal.new(1500),
        due_date: Date.utc_today(),
        description: "Physical Checkup Fee",
        status: "pending",
        payment_reference: "TEST-ONSITE-REF-456"
      })
      
      # Create pending transactions for the invoices
      {:ok, virtual_transaction} = Transaction.create_pending(%{
        clinic_id: clinic.id,
        reference: "TEST-VIRTUAL-REF-123",
        phone: "254711111111",
        amount: 1000,
        type: "stk_push",
        description: "Virtual Consultation Fee",
        checkout_request_id: "ws_CO_123456789",
        merchant_request_id: "123-456-789"
      })
      
      {:ok, onsite_transaction} = Transaction.create_pending(%{
        clinic_id: clinic.id,
        reference: "TEST-ONSITE-REF-456",
        phone: "254711111111",
        amount: 1500,
        type: "stk_push",
        description: "Physical Checkup Fee",
        checkout_request_id: "ws_CO_987654321",
        merchant_request_id: "987-654-321"
      })
      
      %{
        clinic: clinic,
        patient: patient,
        virtual_appointment: virtual_appointment,
        onsite_appointment: onsite_appointment,
        virtual_invoice: virtual_invoice,
        onsite_invoice: onsite_invoice,
        virtual_transaction: virtual_transaction,
        onsite_transaction: onsite_transaction
      }
    end
    
    test "updates invoice status to paid when STK Push callback is successful", %{virtual_transaction: transaction, virtual_invoice: invoice} do
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
                %{"Name" => "MpesaReceiptNumber", "Value" => "LHG31AA4AY"},
                %{"Name" => "TransactionDate", "Value" => 20230601121212},
                %{"Name" => "PhoneNumber", "Value" => "254711111111"}
              ]
            }
          }
        }
      }
      
      # Process the callback
      {:ok, updated_transaction} = Callback.process_stk(callback_payload)
      
      # Verify transaction was updated correctly
      assert updated_transaction.status == "completed"
      assert updated_transaction.mpesa_receipt_number == "LHG31AA4AY"
      
      # Verify invoice was updated correctly
      updated_invoice = Invoices.get_invoice(invoice.id)
      assert updated_invoice.status == "paid"
      assert updated_invoice.notes =~ "Payment processed via M-Pesa"
      assert updated_invoice.notes =~ "LHG31AA4AY"
      
      # Verify appointment was updated correctly
      updated_appointment = Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id)
      assert updated_appointment.status == "confirmed"
      assert updated_appointment.meeting_link != nil
      assert updated_appointment.meeting_link != ""
    end
    
    test "updates invoice status to paid when C2B callback is successful", %{onsite_transaction: transaction, onsite_invoice: invoice} do
      # Create a mock successful C2B callback payload
      callback_payload = %{
        "TransID" => "MJ41H4AABC",
        "TransAmount" => "1500",
        "BillRefNumber" => transaction.reference,
        "MSISDN" => "254711111111",
        "TransactionType" => "Pay Bill",
        "BusinessShortCode" => "123456"
      }
      
      # Process the callback
      {:ok, updated_transaction} = Callback.process_c2b(callback_payload)
      
      # Verify transaction was updated correctly
      assert updated_transaction.status == "completed"
      assert updated_transaction.mpesa_receipt_number == "MJ41H4AABC"
      
      # Verify invoice was updated correctly
      updated_invoice = Invoices.get_invoice(invoice.id)
      assert updated_invoice.status == "paid"
      assert updated_invoice.notes =~ "Payment processed via M-Pesa"
      assert updated_invoice.notes =~ "MJ41H4AABC"
      
      # Verify appointment was updated correctly
      updated_appointment = Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id)
      assert updated_appointment.status == "confirmed"
      # Onsite appointment doesn't need a meeting link
      assert updated_appointment.meeting_link == nil || updated_appointment.meeting_link == ""
    end
    
    test "does not update invoice status when STK Push callback fails", %{virtual_transaction: transaction, virtual_invoice: invoice} do
      # Create a mock failed STK Push callback payload
      callback_payload = %{
        "Body" => %{
          "stkCallback" => %{
            "MerchantRequestID" => transaction.merchant_request_id,
            "CheckoutRequestID" => transaction.checkout_request_id,
            "ResultCode" => "1032",
            "ResultDesc" => "Request cancelled by user"
          }
        }
      }
      
      # Process the callback
      {:ok, updated_transaction} = Callback.process_stk(callback_payload)
      
      # Verify transaction was updated correctly
      assert updated_transaction.status == "failed"
      assert updated_transaction.result_code == "1032"
      
      # Verify invoice status remains unchanged
      updated_invoice = Invoices.get_invoice(invoice.id)
      assert updated_invoice.status == "pending"
      
      # Verify appointment status remains unchanged
      updated_appointment = Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id)
      assert updated_appointment.status == "scheduled"
    end
  end
end
