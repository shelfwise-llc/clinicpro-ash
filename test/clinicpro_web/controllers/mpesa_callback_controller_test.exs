defmodule ClinicproWeb.MPesaCallbackControllerTest do
  @moduledoc """
  Tests for the M-Pesa callback controller.

  This test module verifies that the M-Pesa callback controller properly handles
  STK Push and C2B callbacks, and that the callbacks are correctly processed
  to update invoices and appointments.
  """

  use ClinicproWeb.ConnCase, async: true

  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Invoices
  alias Clinicpro.Appointments

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "M-Pesa callback handling with multi-tenant support" do
    setup do
      # Create test clinics
      {:ok, clinic1} =
        Clinicpro.Clinics.create_clinic(%{
          name: "Test Clinic 1",
          code: "TC1",
          address: "123 Test St",
          phone: "254700000001",
          email: "clinic1@test.com"
        })

      {:ok, clinic2} =
        Clinicpro.Clinics.create_clinic(%{
          name: "Test Clinic 2",
          code: "TC2",
          address: "456 Test Ave",
          phone: "254700000002",
          email: "clinic2@test.com"
        })

      # Create test patients for each clinic
      {:ok, patient1} =
        Clinicpro.Patients.create_patient(%{
          first_name: "John",
          last_name: "Doe",
          phone_number: "254711111111",
          email: "john@example.com",
          clinic_id: clinic1.id
        })

      {:ok, patient2} =
        Clinicpro.Patients.create_patient(%{
          first_name: "Jane",
          last_name: "Smith",
          phone_number: "254722222222",
          email: "jane@example.com",
          clinic_id: clinic2.id
        })

      # Create test appointments for each clinic
      {:ok, appointment1} =
        Appointments.create_appointment(%{
          patient_id: patient1.id,
          clinic_id: clinic1.id,
          date: DateTime.utc_now() |> DateTime.add(1, :day),
          status: "confirmed",
          type: "consultation",
          payment_status: "pending"
        })

      {:ok, appointment2} =
        Appointments.create_appointment(%{
          patient_id: patient2.id,
          clinic_id: clinic2.id,
          date: DateTime.utc_now() |> DateTime.add(1, :day),
          status: "confirmed",
          type: "consultation",
          payment_status: "pending"
        })

      # Create test invoices for each appointment
      {:ok, invoice1} =
        Invoices.create_invoice(%{
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

      {:ok, invoice2} =
        Invoices.create_invoice(%{
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

      # Create transactions for each invoice
      {:ok, transaction1} =
        Transaction.create(%{
          clinic_id: clinic1.id,
          invoice_id: invoice1.id,
          patient_id: patient1.id,
          amount: Decimal.new("1000.00"),
          phone_number: "254711111111",
          status: "pending",
          merchant_request_id: "123456-#{clinic1.id}",
          checkout_request_id: "wx123-#{clinic1.id}",
          reference: invoice1.reference_number
        })

      {:ok, transaction2} =
        Transaction.create(%{
          clinic_id: clinic2.id,
          invoice_id: invoice2.id,
          patient_id: patient2.id,
          amount: Decimal.new("1500.00"),
          phone_number: "254722222222",
          status: "pending",
          merchant_request_id: "789012-#{clinic2.id}",
          checkout_request_id: "wx456-#{clinic2.id}",
          reference: invoice2.reference_number
        })

      # Return the test data
      %{
        clinic1: clinic1,
        clinic2: clinic2,
        patient1: patient1,
        patient2: patient2,
        appointment1: appointment1,
        appointment2: appointment2,
        invoice1: invoice1,
        invoice2: invoice2,
        transaction1: transaction1,
        transaction2: transaction2
      }
    end

    test "stk_callback/2 processes payment for the correct clinic", %{
      conn: conn,
      clinic1: clinic1,
      invoice1: invoice1,
      appointment1: appointment1,
      transaction1: transaction1
    } do
      # Create STK callback payload
      stk_callback_payload = %{
        "Body" => %{
          "stkCallback" => %{
            "MerchantRequestID" => transaction1.merchant_request_id,
            "CheckoutRequestID" => transaction1.checkout_request_id,
            "ResultCode" => 0,
            "ResultDesc" => "The service request is processed successfully.",
            "CallbackMetadata" => %{
              "Item" => [
                %{"Name" => "Amount", "Value" => 1000.00},
                %{"Name" => "MpesaReceiptNumber", "Value" => "LHG31AA5TX"},
                %{"Name" => "TransactionDate", "Value" => 20_230_615_123_456},
                %{"Name" => "PhoneNumber", "Value" => 254_711_111_111}
              ]
            }
          }
        }
      }

      # Send the callback to the controller with clinic_id in the path
      conn = post(conn, ~p"/api/mpesa/callbacks/#{clinic1.id}/stk", stk_callback_payload)

      # Verify the response
      assert json_response(conn, 200) == %{"ResultCode" => "0", "ResultDesc" => "Success"}

      # Verify the transaction was updated
      updated_transaction = Transaction.get(transaction1.id)
      assert updated_transaction.status == "completed"
      assert updated_transaction.transaction_id == "LHG31AA5TX"

      # Verify the invoice was updated
      updated_invoice = Invoices.get_invoice(invoice1.id)
      assert updated_invoice.payment_status == "completed"
      assert updated_invoice.payment_reference == "LHG31AA5TX"
      assert updated_invoice.payment_method == "mpesa"
      assert not is_nil(updated_invoice.payment_date)

      # Verify the appointment was updated
      updated_appointment = Appointments.get_appointment(appointment1.id)
      assert updated_appointment.payment_status == "paid"
    end

    test "stk_callback/2 rejects payment for incorrect clinic", %{
      conn: conn,
      clinic2: clinic2,
      transaction1: transaction1
    } do
      # Create STK callback payload for transaction1 but send to clinic2's endpoint
      stk_callback_payload = %{
        "Body" => %{
          "stkCallback" => %{
            "MerchantRequestID" => transaction1.merchant_request_id,
            "CheckoutRequestID" => transaction1.checkout_request_id,
            "ResultCode" => 0,
            "ResultDesc" => "The service request is processed successfully.",
            "CallbackMetadata" => %{
              "Item" => [
                %{"Name" => "Amount", "Value" => 1000.00},
                %{"Name" => "MpesaReceiptNumber", "Value" => "LHG31AA5TX"},
                %{"Name" => "TransactionDate", "Value" => 20_230_615_123_456},
                %{"Name" => "PhoneNumber", "Value" => 254_711_111_111}
              ]
            }
          }
        }
      }

      # Send the callback to the wrong clinic's endpoint
      conn = post(conn, ~p"/api/mpesa/callbacks/#{clinic2.id}/stk", stk_callback_payload)

      # Verify the response indicates an error
      assert json_response(conn, 200) == %{
               "ResultCode" => "1",
               "ResultDesc" => "Transaction not found or does not belong to this clinic"
             }

      # Verify the transaction was not updated
      unchanged_transaction = Transaction.get(transaction1.id)
      assert unchanged_transaction.status == "pending"
      assert is_nil(unchanged_transaction.transaction_id)
    end

    test "c2b_validation/2 validates payment reference for the correct clinic", %{
      conn: conn,
      clinic1: clinic1,
      invoice1: invoice1
    } do
      # Create C2B validation payload
      validation_payload = %{
        "TransactionType" => "Pay Bill",
        "TransID" => "C2B123456",
        "TransTime" => "20230615123456",
        "TransAmount" => "1000.00",
        "BusinessShortCode" => "123456",
        "BillRefNumber" => invoice1.reference_number,
        "InvoiceNumber" => "",
        "OrgAccountBalance" => "",
        "ThirdPartyTransID" => "",
        "MSISDN" => "254711111111",
        "FirstName" => "John",
        "MiddleName" => "",
        "LastName" => "Doe"
      }

      # Send the validation request to the controller with clinic_id in the path
      conn = post(conn, ~p"/api/mpesa/callbacks/#{clinic1.id}/validation", validation_payload)

      # Verify the response indicates success
      assert json_response(conn, 200) == %{
               "ResultCode" => 0,
               "ResultDesc" => "Accepted"
             }
    end

    test "c2b_validation/2 rejects invalid payment reference", %{
      conn: conn,
      clinic1: clinic1
    } do
      # Create C2B validation payload with invalid reference
      validation_payload = %{
        "TransactionType" => "Pay Bill",
        "TransID" => "C2B123456",
        "TransTime" => "20230615123456",
        "TransAmount" => "1000.00",
        "BusinessShortCode" => "123456",
        "BillRefNumber" => "INVALID-REF",
        "InvoiceNumber" => "",
        "OrgAccountBalance" => "",
        "ThirdPartyTransID" => "",
        "MSISDN" => "254711111111",
        "FirstName" => "John",
        "MiddleName" => "",
        "LastName" => "Doe"
      }

      # Send the validation request to the controller
      conn = post(conn, ~p"/api/mpesa/callbacks/#{clinic1.id}/validation", validation_payload)

      # Verify the response indicates rejection
      assert json_response(conn, 200) == %{
               "ResultCode" => 1,
               "ResultDesc" => "Rejected: Invalid reference number"
             }
    end

    test "c2b_confirmation/2 processes payment for the correct clinic", %{
      conn: conn,
      clinic1: clinic1,
      invoice1: invoice1,
      appointment1: appointment1
    } do
      # Create C2B confirmation payload
      confirmation_payload = %{
        "TransactionType" => "Pay Bill",
        "TransID" => "C2B123456",
        "TransTime" => "20230615123456",
        "TransAmount" => "1000.00",
        "BusinessShortCode" => "123456",
        "BillRefNumber" => invoice1.reference_number,
        "InvoiceNumber" => "",
        "OrgAccountBalance" => "",
        "ThirdPartyTransID" => "",
        "MSISDN" => "254711111111",
        "FirstName" => "John",
        "MiddleName" => "",
        "LastName" => "Doe"
      }

      # Send the confirmation request to the controller with clinic_id in the path
      conn = post(conn, ~p"/api/mpesa/callbacks/#{clinic1.id}/confirmation", confirmation_payload)

      # Verify the response
      assert json_response(conn, 200) == %{
               "ResultCode" => 0,
               "ResultDesc" => "Success"
             }

      # Verify the invoice was updated
      updated_invoice = Invoices.get_invoice(invoice1.id)
      assert updated_invoice.payment_status == "completed"
      assert updated_invoice.payment_reference == "C2B123456"
      assert updated_invoice.payment_method == "mpesa"
      assert not is_nil(updated_invoice.payment_date)

      # Verify the appointment was updated
      updated_appointment = Appointments.get_appointment(appointment1.id)
      assert updated_appointment.payment_status == "paid"

      # Verify a transaction was created
      [transaction] = Transaction.list_by_invoice_id(invoice1.id)
      assert transaction.status == "completed"
      assert transaction.transaction_id == "C2B123456"
      assert transaction.clinic_id == clinic1.id
    end

    test "c2b_confirmation/2 handles orphaned payment for the correct clinic", %{
      conn: conn,
      clinic1: clinic1
    } do
      # Create C2B confirmation payload with non-existent reference
      confirmation_payload = %{
        "TransactionType" => "Pay Bill",
        "TransID" => "C2B789012",
        "TransTime" => "20230615123456",
        "TransAmount" => "2000.00",
        "BusinessShortCode" => "123456",
        "BillRefNumber" => "ORPHANED-PAYMENT",
        "InvoiceNumber" => "",
        "OrgAccountBalance" => "",
        "ThirdPartyTransID" => "",
        "MSISDN" => "254733333333",
        "FirstName" => "Orphaned",
        "MiddleName" => "",
        "LastName" => "Payment"
      }

      # Send the confirmation request to the controller with clinic_id in the path
      conn = post(conn, ~p"/api/mpesa/callbacks/#{clinic1.id}/confirmation", confirmation_payload)

      # Verify the response
      assert json_response(conn, 200) == %{
               "ResultCode" => 0,
               "ResultDesc" => "Success"
             }

      # Verify an orphaned transaction was created
      [transaction] = Transaction.list_orphaned_by_clinic_id(clinic1.id)
      assert transaction.status == "completed"
      assert transaction.transaction_id == "C2B789012"
      assert transaction.clinic_id == clinic1.id
      assert transaction.reference == "ORPHANED-PAYMENT"
      assert is_nil(transaction.invoice_id)
    end
  end
end
