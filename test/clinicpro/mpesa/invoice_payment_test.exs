defmodule Clinicpro.InvoicePaymentTest do
  use Clinicpro.DataCase, async: true

  alias Clinicpro.Invoices.PaymentProcessor
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Invoices
  alias Clinicpro.Appointments

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "invoice payment processing with multi-tenant support" do
    setup do
      # Create test clinics
      {:ok, clinic1} = Clinicpro.Clinics.create_clinic(%{
        name: "Test Clinic 1",
        code: "TC1",
        address: "123 Test St",
        phone: "254700000001",
        email: "clinic1@test.com"
      })

      {:ok, clinic2} = Clinicpro.Clinics.create_clinic(%{
        name: "Test Clinic 2",
        code: "TC2",
        address: "456 Test Ave",
        phone: "254700000002",
        email: "clinic2@test.com"
      })

      # Create test patients for each clinic
      {:ok, patient1} = Clinicpro.Patients.create_patient(%{
        first_name: "John",
        last_name: "Doe",
        phone_number: "254711111111",
        email: "john@example.com",
        clinic_id: clinic1.id
      })

      {:ok, patient2} = Clinicpro.Patients.create_patient(%{
        first_name: "Jane",
        last_name: "Smith",
        phone_number: "254722222222",
        email: "jane@example.com",
        clinic_id: clinic2.id
      })

      # Create test doctors for each clinic
      {:ok, doctor1} = Clinicpro.Doctors.create_doctor(%{
        first_name: "Dr.",
        last_name: "House",
        phone_number: "254733333333",
        email: "house@example.com",
        clinic_id: clinic1.id,
        specialization: "General"
      })

      {:ok, doctor2} = Clinicpro.Doctors.create_doctor(%{
        first_name: "Dr.",
        last_name: "Grey",
        phone_number: "254744444444",
        email: "grey@example.com",
        clinic_id: clinic2.id,
        specialization: "General"
      })

      # Create test appointments for each clinic
      {:ok, appointment1} = Appointments.create_appointment(%{
        patient_id: patient1.id,
        doctor_id: doctor1.id,
        clinic_id: clinic1.id,
        date: DateTime.utc_now() |> DateTime.add(1, :day),
        status: "confirmed",
        type: "consultation",
        payment_status: "pending"
      })

      {:ok, appointment2} = Appointments.create_appointment(%{
        patient_id: patient2.id,
        doctor_id: doctor2.id,
        clinic_id: clinic2.id,
        date: DateTime.utc_now() |> DateTime.add(1, :day),
        status: "confirmed",
        type: "consultation",
        payment_status: "pending"
      })

      # Create test invoices for each appointment
      {:ok, invoice1} = Invoices.create_invoice(%{
        patient_id: patient1.id,
        clinic_id: clinic1.id,
        appointment_id: appointment1.id,
        reference_number: "INV-#{clinic1.code}-001",
        date: DateTime.utc_now(),
        due_date: DateTime.utc_now() |> DateTime.add(7, :day),
        status: "pending",
        payment_status: "pending",
        subtotal: Decimal.new("1000.00"),
        total: Decimal.new("1000.00"),
        items: [
          %{
            description: "Consultation Fee",
            quantity: 1,
            unit_price: Decimal.new("1000.00")
          }
        ]
      })

      {:ok, invoice2} = Invoices.create_invoice(%{
        patient_id: patient2.id,
        clinic_id: clinic2.id,
        appointment_id: appointment2.id,
        reference_number: "INV-#{clinic2.code}-001",
        date: DateTime.utc_now(),
        due_date: DateTime.utc_now() |> DateTime.add(7, :day),
        status: "pending",
        payment_status: "pending",
        subtotal: Decimal.new("1500.00"),
        total: Decimal.new("1500.00"),
        items: [
          %{
            description: "Consultation Fee",
            quantity: 1,
            unit_price: Decimal.new("1500.00")
          }
        ]
      })

      # Mock the M-Pesa STK Push module
      Mox.stub(Clinicpro.MPesa.STKPushMock, :request, fn phone_number, amount, reference, clinic_id ->
        # Return different responses based on clinic_id to test multi-tenant behavior
        case clinic_id do
          ^clinic1.id ->
            {:ok, %{
              "MerchantRequestID" => "123456-#{clinic1.id}",
              "CheckoutRequestID" => "wx123-#{clinic1.id}",
              "ResponseCode" => "0",
              "ResponseDescription" => "Success. Request accepted for processing",
              "CustomerMessage" => "Success. Request accepted for processing"
            }}

          ^clinic2.id ->
            {:ok, %{
              "MerchantRequestID" => "789012-#{clinic2.id}",
              "CheckoutRequestID" => "wx456-#{clinic2.id}",
              "ResponseCode" => "0",
              "ResponseDescription" => "Success. Request accepted for processing",
              "CustomerMessage" => "Success. Request accepted for processing"
            }}

          _ ->
            {:error, "Invalid clinic ID"}
        end
      end)

      # Return the test data
      %{
        clinic1: clinic1,
        clinic2: clinic2,
        patient1: patient1,
        patient2: patient2,
        doctor1: doctor1,
        doctor2: doctor2,
        appointment1: appointment1,
        appointment2: appointment2,
        invoice1: invoice1,
        invoice2: invoice2
      }
    end

    test "initiate_payment/2 creates transaction with correct clinic_id", %{invoice1: invoice1, invoice2: invoice2} do
      # Test payment for clinic 1
      {:ok, response1} = PaymentProcessor.initiate_payment(invoice1, "254711111111")

      # Verify transaction was created with correct clinic_id
      transaction1 = Transaction.get_by_checkout_request_id(response1["CheckoutRequestID"])
      assert transaction1.clinic_id == invoice1.clinic_id
      assert transaction1.invoice_id == invoice1.id
      assert transaction1.status == "pending"

      # Test payment for clinic 2
      {:ok, response2} = PaymentProcessor.initiate_payment(invoice2, "254722222222")

      # Verify transaction was created with correct clinic_id
      transaction2 = Transaction.get_by_checkout_request_id(response2["CheckoutRequestID"])
      assert transaction2.clinic_id == invoice2.clinic_id
      assert transaction2.invoice_id == invoice2.id
      assert transaction2.status == "pending"

      # Verify transactions are isolated by clinic
      clinic1_transactions = Transaction.list_by_clinic_id(invoice1.clinic_id)
      clinic2_transactions = Transaction.list_by_clinic_id(invoice2.clinic_id)

      assert length(clinic1_transactions) == 1
      assert length(clinic2_transactions) == 1
      assert hd(clinic1_transactions).id == transaction1.id
      assert hd(clinic2_transactions).id == transaction2.id
    end

    test "process_callback/1 updates invoice and appointment with correct clinic isolation", %{
      invoice1: invoice1,
      appointment1: appointment1,
      clinic1: clinic1
    } do
      # First initiate a payment
      {:ok, response} = PaymentProcessor.initiate_payment(invoice1, "254711111111")

      # Create a mock callback data that would come from M-Pesa
      callback_data = %{
        merchant_request_id: response["MerchantRequestID"],
        checkout_request_id: response["CheckoutRequestID"],
        result_code: "0",
        result_desc: "The service request is processed successfully.",
        amount: "1000.00",
        mpesa_receipt_number: "LHG31AA5TX",
        transaction_date: "20230615123456",
        phone_number: "254711111111",
        clinic_id: clinic1.id
      }

      # Process the callback
      {:ok, %{invoice: updated_invoice, transaction: updated_transaction}} =
        PaymentProcessor.process_callback(callback_data)

      # Verify invoice was updated
      assert updated_invoice.id == invoice1.id
      assert updated_invoice.payment_status == "completed"
      assert updated_invoice.payment_reference == "LHG31AA5TX"
      assert updated_invoice.payment_method == "mpesa"
      assert not is_nil(updated_invoice.payment_date)

      # Verify transaction was updated
      assert updated_transaction.status == "completed"
      assert updated_transaction.transaction_id == "LHG31AA5TX"

      # Verify appointment was updated
      updated_appointment = Appointments.get_appointment(appointment1.id)
      assert updated_appointment.payment_status == "paid"
    end

    test "check_payment_status/1 returns correct status based on transaction", %{
      invoice1: invoice1,
      invoice2: invoice2
    } do
      # Initiate payment for invoice1
      {:ok, response} = PaymentProcessor.initiate_payment(invoice1, "254711111111")

      # Check status - should be pending
      assert {:ok, :pending} = PaymentProcessor.check_payment_status(invoice1)

      # Update transaction to completed
      transaction = Transaction.get_by_checkout_request_id(response["CheckoutRequestID"])
      {:ok, _} = Transaction.update(transaction, %{
        status: "completed",
        transaction_id: "LHG31AA5TX"
      })

      # Check status again - should be completed
      assert {:ok, :completed} = PaymentProcessor.check_payment_status(invoice1)

      # Check status for invoice2 - should be no transaction
      assert {:ok, :no_transaction} = PaymentProcessor.check_payment_status(invoice2)

      # Create a failed transaction for invoice2
      {:ok, response2} = PaymentProcessor.initiate_payment(invoice2, "254722222222")
      transaction2 = Transaction.get_by_checkout_request_id(response2["CheckoutRequestID"])
      {:ok, _} = Transaction.update(transaction2, %{status: "failed", result_code: "1"})

      # Check status - should be failed
      assert {:ok, :failed} = PaymentProcessor.check_payment_status(invoice2)
    end
  end
end
