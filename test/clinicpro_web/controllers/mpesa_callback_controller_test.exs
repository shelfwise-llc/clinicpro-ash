defmodule ClinicproWeb.MPesaCallbackControllerTest do
  @moduledoc """
  Tests for the M-Pesa callback controller.
  
  This test module verifies that the M-Pesa callback controller properly handles
  STK Push and C2B callbacks, and that the callbacks are correctly processed
  to update invoices and appointments.
  """
  
  use ClinicproWeb.ConnCase
  
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.AdminBypass.{Invoice, Patient, Doctor, Appointment}
  alias Clinicpro.Invoices
  
  describe "M-Pesa callback controller" do
    setup %{conn: conn} do
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
      
      # Create an invoice for the virtual appointment
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
      
      # Create a pending transaction for the invoice
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
      
      %{
        conn: conn,
        clinic: clinic,
        patient: patient,
        virtual_appointment: virtual_appointment,
        virtual_invoice: virtual_invoice,
        virtual_transaction: virtual_transaction
      }
    end
    
    test "handles STK Push callback successfully", %{conn: conn, virtual_transaction: transaction, virtual_invoice: invoice} do
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
      
      # Send the callback to the controller
      conn = post(conn, ~p"/api/mpesa/callbacks/stk", callback_payload)
      
      # Verify the response
      assert json_response(conn, 200) == %{"ResultCode" => 0, "ResultDesc" => "Success"}
      
      # Wait a moment for the async task to complete
      :timer.sleep(100)
      
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
    
    test "handles C2B confirmation callback successfully", %{conn: conn, virtual_transaction: transaction, virtual_invoice: invoice} do
      # Update transaction reference to match C2B format
      {:ok, updated_transaction} = Transaction.update(transaction, %{
        type: "c2b"
      })
      
      # Create a mock successful C2B callback payload
      callback_payload = %{
        "TransID" => "MJ41H4AABC",
        "TransAmount" => "1000",
        "BillRefNumber" => updated_transaction.reference,
        "MSISDN" => "254711111111",
        "TransactionType" => "Pay Bill",
        "BusinessShortCode" => "123456"
      }
      
      # Send the callback to the controller
      conn = post(conn, ~p"/api/mpesa/callbacks/c2b/confirmation", callback_payload)
      
      # Verify the response
      assert json_response(conn, 200) == %{"ResultCode" => 0, "ResultDesc" => "Success"}
      
      # Wait a moment for the async task to complete
      :timer.sleep(100)
      
      # Verify invoice was updated correctly
      updated_invoice = Invoices.get_invoice(invoice.id)
      assert updated_invoice.status == "paid"
      assert updated_invoice.notes =~ "Payment processed via M-Pesa"
      assert updated_invoice.notes =~ "MJ41H4AABC"
      
      # Verify appointment was updated correctly
      updated_appointment = Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id)
      assert updated_appointment.status == "confirmed"
      assert updated_appointment.meeting_link != nil
      assert updated_appointment.meeting_link != ""
    end
    
    test "handles C2B validation callback successfully", %{conn: conn} do
      # Create a mock C2B validation payload
      validation_payload = %{
        "TransID" => "VAL123456",
        "TransAmount" => "1000",
        "BillRefNumber" => "TEST-VIRTUAL-REF-123",
        "MSISDN" => "254711111111",
        "TransactionType" => "Pay Bill",
        "BusinessShortCode" => "123456"
      }
      
      # Send the validation callback to the controller
      conn = post(conn, ~p"/api/mpesa/callbacks/c2b/validation", validation_payload)
      
      # Verify the response - should always accept the transaction at validation stage
      assert json_response(conn, 200) == %{"ResultCode" => 0, "ResultDesc" => "Accepted"}
    end
    
    test "handles failed STK Push callback correctly", %{conn: conn, virtual_transaction: transaction, virtual_invoice: invoice} do
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
      
      # Send the callback to the controller
      conn = post(conn, ~p"/api/mpesa/callbacks/stk", callback_payload)
      
      # Verify the response - should always return success to M-Pesa
      assert json_response(conn, 200) == %{"ResultCode" => 0, "ResultDesc" => "Success"}
      
      # Wait a moment for the async task to complete
      :timer.sleep(100)
      
      # Verify invoice status remains unchanged
      updated_invoice = Invoices.get_invoice(invoice.id)
      assert updated_invoice.status == "pending"
      
      # Verify appointment status remains unchanged
      updated_appointment = Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id)
      assert updated_appointment.status == "scheduled"
    end
  end
end
