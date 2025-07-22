defmodule Clinicpro.InvoicesTest do
  @moduledoc """
  Tests for the Invoices module.
  
  This test module verifies that the Invoices module correctly processes
  completed payments, updates invoice status, and handles different
  appointment types appropriately.
  """
  
  use Clinicpro.DataCase
  
  alias Clinicpro.AdminBypass.{Invoice, Patient, Doctor, Appointment}
  alias Clinicpro.Invoices
  alias Clinicpro.MPesa.Transaction
  
  describe "process_completed_payment/1" do
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
      
      # Create completed transactions for the invoices
      {:ok, virtual_transaction} = Transaction.create_pending(%{
        clinic_id: clinic.id,
        reference: "TEST-VIRTUAL-REF-123",
        phone: "254711111111",
        amount: 1000,
        type: "stk_push",
        description: "Virtual Consultation Fee"
      })
      
      # Update transaction to completed status
      {:ok, virtual_transaction} = Transaction.update(virtual_transaction, %{
        status: "completed",
        mpesa_receipt_number: "LHG31AA4AY",
        transaction_date: "20230601121212"
      })
      
      {:ok, onsite_transaction} = Transaction.create_pending(%{
        clinic_id: clinic.id,
        reference: "TEST-ONSITE-REF-456",
        phone: "254711111111",
        amount: 1500,
        type: "stk_push",
        description: "Physical Checkup Fee"
      })
      
      # Update transaction to completed status
      {:ok, onsite_transaction} = Transaction.update(onsite_transaction, %{
        status: "completed",
        mpesa_receipt_number: "MJ41H4AABC",
        transaction_date: "20230601141414"
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
    
    test "updates virtual appointment invoice and generates meeting link", %{virtual_transaction: transaction, virtual_invoice: invoice} do
      # Process the completed payment
      {:ok, updated_invoice} = Invoices.process_completed_payment(transaction)
      
      # Verify invoice was updated correctly
      assert updated_invoice.status == "paid"
      assert updated_invoice.notes =~ "Payment processed via M-Pesa"
      assert updated_invoice.notes =~ transaction.mpesa_receipt_number
      
      # Verify appointment was updated correctly
      updated_appointment = Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id)
      assert updated_appointment.status == "confirmed"
      assert updated_appointment.meeting_link != nil
      assert updated_appointment.meeting_link != ""
    end
    
    test "updates onsite appointment invoice without generating meeting link", %{onsite_transaction: transaction, onsite_invoice: invoice} do
      # Process the completed payment
      {:ok, updated_invoice} = Invoices.process_completed_payment(transaction)
      
      # Verify invoice was updated correctly
      assert updated_invoice.status == "paid"
      assert updated_invoice.notes =~ "Payment processed via M-Pesa"
      assert updated_invoice.notes =~ transaction.mpesa_receipt_number
      
      # Verify appointment was updated correctly
      updated_appointment = Clinicpro.AdminBypass.Appointment.get_appointment!(invoice.appointment_id)
      assert updated_appointment.status == "confirmed"
      # Onsite appointment doesn't need a meeting link
      assert updated_appointment.meeting_link == nil || updated_appointment.meeting_link == ""
    end
  end
end
