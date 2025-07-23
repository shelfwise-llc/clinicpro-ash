defmodule Clinicpro.MPesaModuleTest do
  @moduledoc """
  Focused test for the M-Pesa modules to verify our fixes.
  """

  use Clinicpro.DataCase

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, Transaction, MockSTKPush, C2B}

  # Setup test clinics
  @clinic_1_id 1
  @clinic_2_id 2

  describe "M-Pesa module fixes" do
    test "C2B process_confirmation with unused variable fix" do
      # Create a test transaction
      {:ok, transaction} = Transaction.create(%{
        clinic_id: @clinic_1_id,
        phone_number: "254712345678",
        amount: 1000.0,
        reference: "TEST-REF",
        description: "Test payment",
        status: "pending",
        payment_method: "c2b",
        transaction_type: "payment"
      })

      # Create test confirmation data
      confirmation_data = %{
        "TransID" => "MPESA123",
        "TransAmount" => "1000.00",
        "BillRefNumber" => transaction.reference,
        "MSISDN" => "254712345678",
        "FirstName" => "John",
        "MiddleName" => "M",
        "LastName" => "Doe",
        "OrgAccountBalance" => "5000.00",
        "TransTime" => "20230101000000",
        "BusinessShortCode" => "123456"
      }

      # Process the confirmation - this should not raise any errors
      result = C2B.process_confirmation(confirmation_data, @clinic_1_id)
      assert {:ok, _} = result
    end

    test "MockSTKPush with unused variable fixes" do
      # Test send_stk_push with unused variables
      result = MockSTKPush.send_stk_push(
        "254712345678",
        1000.0,
        "TEST-REF",
        "Test payment",
        "123456"
      )
      
      assert {:ok, %{checkout_request_id: _, merchant_request_id: _}} = result

      # Test query_stk_push_status with unused variables
      status_result = MockSTKPush.query_stk_push_status("CHECKOUT123", "MERCHANT123", @clinic_1_id)
      assert {:ok, _} = status_result
    end
  end
end
