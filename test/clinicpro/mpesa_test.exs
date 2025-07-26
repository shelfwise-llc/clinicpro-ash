defmodule Clinicpro.MPesaTest do
  use Clinicpro.DataCase

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, Transaction}
  alias Clinicpro.AdminBypass.Doctor

  # Mock HTTP client for testing
  defmodule MockHTTP do
    def post(url, _body, _headers) do
      cond do
        String.contains?(url, "oauth/v1/generate") ->
          {:ok, %{status_code: 200, body: Jason.encode!(%{"access_token" => "test_token"})}}

        String.contains?(url, "mpesa/stkpush/v1/processrequest") ->
          {:ok,
           %{
             status_code: 200,
             body:
               Jason.encode!(%{
                 "MerchantRequestID" => "test-merchant-id",
                 "CheckoutRequestID" => "test-checkout-id",
                 "ResponseCode" => "0",
                 "ResponseDescription" => "Success"
               })
           }}

        String.contains?(url, "mpesa/c2b/v1/registerurl") ->
          {:ok,
           %{
             status_code: 200,
             body:
               Jason.encode!(%{
                 "ResponseCode" => "0",
                 "ResponseDescription" => "Success"
               })
           }}

        String.contains?(url, "mpesa/stkpushquery/v1/query") ->
          {:ok,
           %{
             status_code: 200,
             body:
               Jason.encode!(%{
                 "ResponseCode" => "0",
                 "ResponseDescription" => "Success",
                 "ResultCode" => "0",
                 "ResultDesc" => "The service request is processed successfully."
               })
           }}

        true ->
          {:error, %{reason: "Unknown URL"}}
      end
    end
  end

  setup do
    # Create test clinics
    {:ok, clinic1} = Doctor.create(%{name: "Test Clinic 1", email: "clinic1@example.com"})
    {:ok, clinic2} = Doctor.create(%{name: "Test Clinic 2", email: "clinic2@example.com"})

    # Create M-Pesa configs for both clinics
    {:ok, _config1} =
      MPesa.create_config(%{
        clinic_id: clinic1.id,
        consumer_key: "test_key_1",
        consumer_secret: "test_secret_1",
        passkey: "test_passkey_1",
        shortcode: "123456",
        environment: "sandbox"
      })

    {:ok, _config2} =
      MPesa.create_config(%{
        clinic_id: clinic2.id,
        consumer_key: "test_key_2",
        consumer_secret: "test_secret_2",
        passkey: "test_passkey_2",
        shortcode: "654321",
        environment: "sandbox"
      })

    # Return test data
    %{clinic1: clinic1, clinic2: clinic2}
  end

  describe "multi-tenant configuration" do
    test "each clinic has its own M-Pesa configuration", %{clinic1: clinic1, clinic2: clinic2} do
      {:ok, config1} = Config.get_for_clinic(clinic1.id)
      {:ok, config2} = Config.get_for_clinic(clinic2.id)

      assert config1.consumer_key == "test_key_1"
      assert config2.consumer_key == "test_key_2"
      assert config1.shortcode != config2.shortcode
    end

    test "returns error when config not found" do
      assert {:error, :config_not_found} = Config.get_for_clinic(999)
    end
  end

  describe "STK Push" do
    test "initiates STK Push transaction", %{clinic1: clinic1} do
      # Mock the HTTP client
      original_http_client = Application.get_env(:clinicpro, :http_client)
      Application.put_env(:clinicpro, :http_client, MockHTTP)

      try do
        result =
          MPesa.initiate_stk_push(
            clinic1.id,
            "254712345678",
            100,
            "TEST123",
            "Test Payment"
          )

        assert {:ok, transaction} = result
        assert transaction.checkout_request_id == "test-checkout-id"
        assert transaction.merchant_request_id == "test-merchant-id"
        assert transaction.status == "pending"
        assert transaction.clinic_id == clinic1.id
        assert transaction.amount == Decimal.new(100)
      after
        # Restore the original HTTP client
        Application.put_env(:clinicpro, :http_client, original_http_client)
      end
    end

    test "handles STK Push failure", %{clinic1: clinic1} do
      # Mock the HTTP client to simulate failure
      defmodule FailureHTTP do
        def post(_url, _body, _headers) do
          {:error, %{reason: "Connection failed"}}
        end
      end

      original_http_client = Application.get_env(:clinicpro, :http_client)
      Application.put_env(:clinicpro, :http_client, FailureHTTP)

      try do
        result =
          MPesa.initiate_stk_push(
            clinic1.id,
            "254712345678",
            100,
            "TEST123",
            "Test Payment"
          )

        assert {:error, _reason} = result
      after
        # Restore the original HTTP client
        Application.put_env(:clinicpro, :http_client, original_http_client)
      end
    end
  end

  describe "C2B URL registration" do
    test "registers C2B URLs for a clinic", %{clinic1: clinic1} do
      # Mock the HTTP client
      original_http_client = Application.get_env(:clinicpro, :http_client)
      Application.put_env(:clinicpro, :http_client, MockHTTP)

      try do
        result = MPesa.register_c2b_urls(clinic1.id)
        assert {:ok, _response} = result
      after
        # Restore the original HTTP client
        Application.put_env(:clinicpro, :http_client, original_http_client)
      end
    end
  end

  describe "Transaction management" do
    test "creates pending transaction", %{clinic1: clinic1} do
      attrs = %{
        clinic_id: clinic1.id,
        phone: "254712345678",
        amount: 100,
        reference: "TEST123",
        description: "Test Payment",
        type: "stk_push"
      }

      assert {:ok, transaction} = Transaction.create_pending(attrs)
      assert transaction.status == "pending"
      assert transaction.clinic_id == clinic1.id
    end

    test "lists transactions for a clinic", %{clinic1: clinic1, clinic2: clinic2} do
      # Create transactions for clinic1
      {:ok, _unused} =
        Transaction.create_pending(%{
          clinic_id: clinic1.id,
          phone: "254712345678",
          amount: 100,
          reference: "CLINIC1-1",
          type: "stk_push"
        })

      {:ok, _unused} =
        Transaction.create_pending(%{
          clinic_id: clinic1.id,
          phone: "254712345678",
          amount: 200,
          reference: "CLINIC1-2",
          type: "stk_push"
        })

      # Create transaction for clinic2
      {:ok, _unused} =
        Transaction.create_pending(%{
          clinic_id: clinic2.id,
          phone: "254712345678",
          amount: 300,
          reference: "CLINIC2-1",
          type: "stk_push"
        })

      # List transactions for clinic1
      transactions1 = MPesa.list_transactions(clinic1.id)
      assert length(transactions1) == 2

      # List transactions for clinic2
      transactions2 = MPesa.list_transactions(clinic2.id)
      assert length(transactions2) == 1
    end
  end

  describe "Callback processing" do
    test "processes STK callback" do
      # Create a pending transaction
      {:ok, transaction} =
        Transaction.create_pending(%{
          clinic_id: 1,
          phone: "254712345678",
          amount: 100,
          reference: "TEST-STK",
          type: "stk_push",
          checkout_request_id: "test-checkout-id"
        })

      # Update with request IDs
      {:ok, transaction} =
        Transaction.update(transaction, %{
          checkout_request_id: "test-checkout-id",
          merchant_request_id: "test-merchant-id"
        })

      # Simulate STK callback payload
      payload = %{
        "Body" => %{
          "stkCallback" => %{
            "MerchantRequestID" => "test-merchant-id",
            "CheckoutRequestID" => "test-checkout-id",
            "ResultCode" => 0,
            "ResultDesc" => "The service request is processed successfully.",
            "CallbackMetadata" => %{
              "Item" => [
                %{"Name" => "Amount", "Value" => 100},
                %{"Name" => "MpesaReceiptNumber", "Value" => "TEST123456"},
                %{"Name" => "TransactionDate", "Value" => 20_250_722_100_436},
                %{"Name" => "PhoneNumber", "Value" => 254_712_345_678}
              ]
            }
          }
        }
      }

      result = MPesa.process_stk_callback(payload)
      assert {:ok, updated_transaction} = result
      assert updated_transaction.status == "completed"
      assert updated_transaction.mpesa_receipt_number == "TEST123456"
    end
  end
end
