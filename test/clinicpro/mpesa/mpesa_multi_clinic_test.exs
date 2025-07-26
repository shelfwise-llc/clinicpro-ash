defmodule Clinicpro.MPesaMultiClinicTest do
  @moduledoc """
  Tests for the M-Pesa integration with multi-tenant support.
  """

  use Clinicpro.DataCase

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, Transaction, MockSTKPush}

  # Setup test clinics
  @clinic_1_id 1
  @clinic_2_id 2

  describe "multi-tenant M-Pesa configuration" do
    test "creates clinic-specific configurations" do
      # Create config for clinic 1
      {:ok, config1} =
        Config.create(%{
          clinic_id: @clinic_1_id,
          consumer_key: "test_key_1",
          consumer_secret: "test_secret_1",
          passkey: "test_passkey_1",
          shortcode: "123456",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic1",
          validation_url: "https://example.com/mpesa/validate/clinic1",
          confirmation_url: "https://example.com/mpesa/confirm/clinic1",
          active: true
        })

      # Create config for clinic 2
      {:ok, config2} =
        Config.create(%{
          clinic_id: @clinic_2_id,
          consumer_key: "test_key_2",
          consumer_secret: "test_secret_2",
          passkey: "test_passkey_2",
          shortcode: "654321",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic2",
          validation_url: "https://example.com/mpesa/validate/clinic2",
          confirmation_url: "https://example.com/mpesa/confirm/clinic2",
          active: true
        })

      # Verify configs were created with correct clinic IDs
      assert config1.clinic_id == @clinic_1_id
      assert config2.clinic_id == @clinic_2_id

      # Verify configs can be retrieved by clinic ID
      assert Config.get_config(@clinic_1_id).consumer_key == "test_key_1"
      assert Config.get_config(@clinic_2_id).consumer_key == "test_key_2"

      # Verify configs are isolated by clinic ID
      configs = Config.list_configs()
      assert length(configs) == 2

      clinic1_configs = Config.list_configs(@clinic_1_id)
      assert length(clinic1_configs) == 1
      assert hd(clinic1_configs).clinic_id == @clinic_1_id

      clinic2_configs = Config.list_configs(@clinic_2_id)
      assert length(clinic2_configs) == 1
      assert hd(clinic2_configs).clinic_id == @clinic_2_id
    end

    test "activates and deactivates configurations" do
      # Create config for clinic 1
      {:ok, config} =
        Config.create(%{
          clinic_id: @clinic_1_id,
          consumer_key: "test_key_1",
          consumer_secret: "test_secret_1",
          passkey: "test_passkey_1",
          shortcode: "123456",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic1",
          validation_url: "https://example.com/mpesa/validate/clinic1",
          confirmation_url: "https://example.com/mpesa/confirm/clinic1",
          active: true
        })

      # Deactivate config
      {:ok, updated_config} = Config.deactivate(config.id)
      assert updated_config.active == false

      # Activate config
      {:ok, reactivated_config} = Config.activate(config.id)
      assert reactivated_config.active == true
    end
  end

  describe "multi-tenant M-Pesa transactions" do
    setup do
      # Create configs for both clinics
      {:ok, _config1} =
        Config.create(%{
          clinic_id: @clinic_1_id,
          consumer_key: "test_key_1",
          consumer_secret: "test_secret_1",
          passkey: "test_passkey_1",
          shortcode: "123456",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic1",
          validation_url: "https://example.com/mpesa/validate/clinic1",
          confirmation_url: "https://example.com/mpesa/confirm/clinic1",
          active: true
        })

      {:ok, _config2} =
        Config.create(%{
          clinic_id: @clinic_2_id,
          consumer_key: "test_key_2",
          consumer_secret: "test_secret_2",
          passkey: "test_passkey_2",
          shortcode: "654321",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic2",
          validation_url: "https://example.com/mpesa/validate/clinic2",
          confirmation_url: "https://example.com/mpesa/confirm/clinic2",
          active: true
        })

      :ok
    end

    test "creates transactions isolated by clinic" do
      # Create transaction for clinic 1
      {:ok, tx1} =
        Transaction.create(%{
          clinic_id: @clinic_1_id,
          invoice_id: "INV-001",
          patient_id: "PAT-001",
          phone_number: "254712345678",
          amount: 1000.0,
          status: "pending"
        })

      # Create transaction for clinic 2
      {:ok, tx2} =
        Transaction.create(%{
          clinic_id: @clinic_2_id,
          invoice_id: "INV-002",
          patient_id: "PAT-002",
          phone_number: "254712345679",
          amount: 2000.0,
          status: "pending"
        })

      # Verify transactions were created with correct clinic IDs
      assert tx1.clinic_id == @clinic_1_id
      assert tx2.clinic_id == @clinic_2_id

      # Verify transactions are isolated by clinic ID
      clinic1_txs = Transaction.list_by_clinic(@clinic_1_id)
      assert length(clinic1_txs) == 1
      assert hd(clinic1_txs).clinic_id == @clinic_1_id

      clinic2_txs = Transaction.list_by_clinic(@clinic_2_id)
      assert length(clinic2_txs) == 1
      assert hd(clinic2_txs).clinic_id == @clinic_2_id
    end

    test "updates transactions with request IDs" do
      # Create transaction for clinic 1
      {:ok, tx} =
        Transaction.create(%{
          clinic_id: @clinic_1_id,
          invoice_id: "INV-001",
          patient_id: "PAT-001",
          phone_number: "254712345678",
          amount: 1000.0,
          status: "pending"
        })

      # Update with request IDs
      {:ok, updated_tx} = Transaction.update_request_ids(tx.id, "checkout-123", "merchant-123")

      # Verify update
      assert updated_tx.checkout_request_id == "checkout-123"
      assert updated_tx.merchant_request_id == "merchant-123"

      # Verify retrieval by request IDs
      assert Transaction.get_by_checkout_request_id("checkout-123").id == tx.id
      assert Transaction.get_by_merchant_request_id("merchant-123").id == tx.id
    end

    test "updates transaction status" do
      # Create transaction for clinic 1
      {:ok, tx} =
        Transaction.create(%{
          clinic_id: @clinic_1_id,
          invoice_id: "INV-001",
          patient_id: "PAT-001",
          phone_number: "254712345678",
          amount: 1000.0,
          status: "pending"
        })

      # Update status to completed
      {:ok, updated_tx} = Transaction.update_status(tx.id, "completed", "0", "Success")

      # Verify update
      assert updated_tx.status == "completed"
      assert updated_tx.result_code == "0"
      assert updated_tx.result_desc == "Success"
    end
  end

  describe "M-Pesa STK Push with multi-tenant support" do
    setup do
      # Create configs for both clinics
      {:ok, _config1} =
        Config.create(%{
          clinic_id: @clinic_1_id,
          consumer_key: "test_key_1",
          consumer_secret: "test_secret_1",
          passkey: "test_passkey_1",
          shortcode: "123456",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic1",
          validation_url: "https://example.com/mpesa/validate/clinic1",
          confirmation_url: "https://example.com/mpesa/confirm/clinic1",
          active: true
        })

      {:ok, _config2} =
        Config.create(%{
          clinic_id: @clinic_2_id,
          consumer_key: "test_key_2",
          consumer_secret: "test_secret_2",
          passkey: "test_passkey_2",
          shortcode: "654321",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic2",
          validation_url: "https://example.com/mpesa/validate/clinic2",
          confirmation_url: "https://example.com/mpesa/confirm/clinic2",
          active: true
        })

      # Configure application to use MockSTKPush
      Application.put_env(:clinicpro, :mpesa_stk_push_module, Clinicpro.MPesa.MockSTKPush)

      on_exit(fn ->
        # Reset application environment
        Application.delete_env(:clinicpro, :mpesa_stk_push_module)
      end)

      :ok
    end

    test "initiates STK Push for different clinics" do
      # Initiate STK Push for clinic 1
      {:ok, %{transaction: tx1, checkout_request_id: checkout1, merchant_request_id: merchant1}} =
        MPesa.initiate_stk_push("254712345678", 1000.0, "INV-001", "Test payment", @clinic_1_id)

      # Initiate STK Push for clinic 2
      {:ok, %{transaction: tx2, checkout_request_id: checkout2, merchant_request_id: merchant2}} =
        MPesa.initiate_stk_push("254712345679", 2000.0, "INV-002", "Test payment", @clinic_2_id)

      # Verify transactions were created with correct clinic IDs
      assert tx1.clinic_id == @clinic_1_id
      assert tx2.clinic_id == @clinic_2_id

      # Verify request IDs were set
      assert tx1.checkout_request_id == checkout1
      assert tx1.merchant_request_id == merchant1
      assert tx2.checkout_request_id == checkout2
      assert tx2.merchant_request_id == merchant2

      # Verify transactions are isolated by clinic ID
      clinic1_txs = Transaction.list_by_clinic(@clinic_1_id)
      assert length(clinic1_txs) == 1
      assert hd(clinic1_txs).clinic_id == @clinic_1_id

      clinic2_txs = Transaction.list_by_clinic(@clinic_2_id)
      assert length(clinic2_txs) == 1
      assert hd(clinic2_txs).clinic_id == @clinic_2_id
    end

    test "processes STK Push callbacks for different clinics" do
      # Initiate STK Push for clinic 1
      {:ok, %{transaction: tx1, checkout_request_id: checkout1, merchant_request_id: merchant1}} =
        MPesa.initiate_stk_push("254712345678", 1000.0, "INV-001", "Test payment", @clinic_1_id)

      # Initiate STK Push for clinic 2
      {:ok, %{transaction: tx2, checkout_request_id: checkout2, merchant_request_id: merchant2}} =
        MPesa.initiate_stk_push("254712345679", 2000.0, "INV-002", "Test payment", @clinic_2_id)

      # Simulate callbacks
      {:ok, callback1} =
        MockSTKPush.simulate_callback(
          checkout1,
          merchant1,
          "254712345678",
          1000.0,
          "MPESA123",
          true
        )

      {:ok, callback2} =
        MockSTKPush.simulate_callback(
          checkout2,
          merchant2,
          "254712345679",
          2000.0,
          "MPESA456",
          true
        )

      # Process callbacks
      {:ok, _unused} = MPesa.process_stk_push_callback(callback1)
      {:ok, _unused} = MPesa.process_stk_push_callback(callback2)

      # Verify transactions were updated
      updated_tx1 = Transaction.get_by_id(tx1.id)
      updated_tx2 = Transaction.get_by_id(tx2.id)

      assert updated_tx1.status == "completed"
      assert updated_tx1.transaction_id == "MPESA123"

      assert updated_tx2.status == "completed"
      assert updated_tx2.transaction_id == "MPESA456"
    end
  end

  describe "M-Pesa C2B with multi-tenant support" do
    setup do
      # Create configs for both clinics
      {:ok, _config1} =
        Config.create(%{
          clinic_id: @clinic_1_id,
          consumer_key: "test_key_1",
          consumer_secret: "test_secret_1",
          passkey: "test_passkey_1",
          shortcode: "123456",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic1",
          validation_url: "https://example.com/mpesa/validate/clinic1",
          confirmation_url: "https://example.com/mpesa/confirm/clinic1",
          active: true
        })

      {:ok, _config2} =
        Config.create(%{
          clinic_id: @clinic_2_id,
          consumer_key: "test_key_2",
          consumer_secret: "test_secret_2",
          passkey: "test_passkey_2",
          shortcode: "654321",
          environment: "sandbox",
          base_url: "https://sandbox.safaricom.co.ke",
          callback_url: "https://example.com/mpesa/callback/clinic2",
          validation_url: "https://example.com/mpesa/validate/clinic2",
          confirmation_url: "https://example.com/mpesa/confirm/clinic2",
          active: true
        })

      :ok
    end

    test "processes C2B callbacks for different clinics" do
      # Create transactions for both clinics
      {:ok, tx1} =
        Transaction.create(%{
          clinic_id: @clinic_1_id,
          invoice_id: "INV-001",
          patient_id: "PAT-001",
          phone_number: "254712345678",
          amount: 1000.0,
          status: "pending",
          reference: "INV-001"
        })

      {:ok, tx2} =
        Transaction.create(%{
          clinic_id: @clinic_2_id,
          invoice_id: "INV-002",
          patient_id: "PAT-002",
          phone_number: "254712345679",
          amount: 2000.0,
          status: "pending",
          reference: "INV-002"
        })

      # Simulate C2B callbacks
      {:ok, callback1} =
        MockSTKPush.simulate_c2b_callback(
          "123456",
          "254712345678",
          1000.0,
          "INV-001",
          "MPESA123"
        )

      {:ok, callback2} =
        MockSTKPush.simulate_c2b_callback(
          "654321",
          "254712345679",
          2000.0,
          "INV-002",
          "MPESA456"
        )

      # Process callbacks
      {:ok, _unused} = MPesa.process_c2b_confirmation(callback1)
      {:ok, _unused} = MPesa.process_c2b_confirmation(callback2)

      # Verify transactions were updated
      updated_tx1 = Transaction.get_by_id(tx1.id)
      updated_tx2 = Transaction.get_by_id(tx2.id)

      assert updated_tx1.status == "completed"
      assert updated_tx1.transaction_id == "MPESA123"

      assert updated_tx2.status == "completed"
      assert updated_tx2.transaction_id == "MPESA456"
    end
  end
end
