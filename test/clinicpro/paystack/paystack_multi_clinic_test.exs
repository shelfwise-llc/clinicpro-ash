defmodule Clinicpro.PaystackMultiClinicTest do
  use Clinicpro.DataCase

  alias Clinicpro.Paystack
  alias Clinicpro.Paystack.Config
  alias Clinicpro.Paystack.Subaccount
  alias Clinicpro.Paystack.Transaction

  @clinic_1_id 1
  @clinic_2_id 2
  @valid_config_attrs %{
    name: "Test Config",
    public_key: "pk_test_123456789",
    secret_key: "sk_test_123456789",
    webhook_secret: "whsec_123456789",
    environment: "test",
    is_active: true,
    description: "Test configuration"
  }
  @valid_subaccount_attrs %{
    business_name: "Test Business",
    settlement_bank: "044",
    account_number: "0123456789",
    percentage_charge: 20.0,
    is_active: true,
    description: "Test subaccount"
  }
  @valid_transaction_attrs %{
    email: "customer@example.com",
    amount: 1000,
    reference: "test_ref_123",
    description: "Test transaction"
  }

  describe "multi-tenant configuration management" do
    test "create_config/2 creates a config for a specific clinic" do
      assert {:ok, %Config{} = config} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)
      assert config.clinic_id == @clinic_1_id
      assert config.name == @valid_config_attrs.name
      assert config.is_active == true
    end

    test "get_active_config/1 returns the active config for a specific clinic" do
      {:ok, config1} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)

      {:ok, config2} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 2 Config"),
          @clinic_2_id
        )

      assert {:ok, fetched_config1} = Paystack.get_active_config(@clinic_1_id)
      assert {:ok, fetched_config2} = Paystack.get_active_config(@clinic_2_id)

      assert fetched_config1.id == config1.id
      assert fetched_config2.id == config2.id
      assert fetched_config1.clinic_id == @clinic_1_id
      assert fetched_config2.clinic_id == @clinic_2_id
    end

    test "list_configs/1 only returns configs for the specified clinic" do
      {:ok, _config1} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)

      {:ok, _config2} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 1 Config 2"),
          @clinic_1_id
        )

      {:ok, _config3} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 2 Config"),
          @clinic_2_id
        )

      clinic1_configs = Paystack.list_configs(@clinic_1_id)
      clinic2_configs = Paystack.list_configs(@clinic_2_id)

      assert length(clinic1_configs) == 2
      assert length(clinic2_configs) == 1
      assert Enum.all?(clinic1_configs, fn c -> c.clinic_id == @clinic_1_id end)
      assert Enum.all?(clinic2_configs, fn c -> c.clinic_id == @clinic_2_id end)
    end

    test "activate_config/2 only activates the config for the specified clinic" do
      {:ok, config1} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)

      {:ok, config2} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 1 Config 2", :is_active, false),
          @clinic_1_id
        )

      {:ok, config3} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 2 Config"),
          @clinic_2_id
        )

      # Activate the second config for clinic 1
      {:ok, activated_config} = Paystack.activate_config(config2.id, @clinic_1_id)
      assert activated_config.is_active == true

      # The first config for clinic 1 should now be inactive
      {:ok, updated_config1} = Paystack.get_config(config1.id, @clinic_1_id)
      assert updated_config1.is_active == false

      # The config for clinic 2 should still be active
      {:ok, updated_config3} = Paystack.get_config(config3.id, @clinic_2_id)
      assert updated_config3.is_active == true
    end
  end

  describe "multi-tenant subaccount management" do
    setup do
      {:ok, config1} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)

      {:ok, config2} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 2 Config"),
          @clinic_2_id
        )

      %{config1: config1, config2: config2}
    end

    test "create_subaccount/2 creates a subaccount for a specific clinic", %{config1: _config1} do
      assert {:ok, %Subaccount{} = subaccount} =
               Paystack.create_subaccount(@valid_subaccount_attrs, @clinic_1_id)

      assert subaccount.clinic_id == @clinic_1_id
      assert subaccount.business_name == @valid_subaccount_attrs.business_name
      assert subaccount.is_active == true
    end

    test "get_active_subaccount/1 returns the active subaccount for a specific clinic", %{
      config1: _config1,
      config2: _config2
    } do
      {:ok, subaccount1} = Paystack.create_subaccount(@valid_subaccount_attrs, @clinic_1_id)

      {:ok, subaccount2} =
        Paystack.create_subaccount(
          Map.put(@valid_subaccount_attrs, :business_name, "Clinic 2 Business"),
          @clinic_2_id
        )

      assert {:ok, fetched_subaccount1} = Paystack.get_active_subaccount(@clinic_1_id)
      assert {:ok, fetched_subaccount2} = Paystack.get_active_subaccount(@clinic_2_id)

      assert fetched_subaccount1.id == subaccount1.id
      assert fetched_subaccount2.id == subaccount2.id
      assert fetched_subaccount1.clinic_id == @clinic_1_id
      assert fetched_subaccount2.clinic_id == @clinic_2_id
    end

    test "list_subaccounts/1 only returns subaccounts for the specified clinic", %{
      config1: _config1,
      config2: _config2
    } do
      {:ok, _subaccount1} = Paystack.create_subaccount(@valid_subaccount_attrs, @clinic_1_id)

      {:ok, _subaccount2} =
        Paystack.create_subaccount(
          Map.put(@valid_subaccount_attrs, :business_name, "Clinic 1 Business 2"),
          @clinic_1_id
        )

      {:ok, _subaccount3} =
        Paystack.create_subaccount(
          Map.put(@valid_subaccount_attrs, :business_name, "Clinic 2 Business"),
          @clinic_2_id
        )

      clinic1_subaccounts = Paystack.list_subaccounts(@clinic_1_id)
      clinic2_subaccounts = Paystack.list_subaccounts(@clinic_2_id)

      assert length(clinic1_subaccounts) == 2
      assert length(clinic2_subaccounts) == 1
      assert Enum.all?(clinic1_subaccounts, fn s -> s.clinic_id == @clinic_1_id end)
      assert Enum.all?(clinic2_subaccounts, fn s -> s.clinic_id == @clinic_2_id end)
    end
  end

  describe "multi-tenant transaction management" do
    setup do
      {:ok, config1} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)

      {:ok, config2} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 2 Config"),
          @clinic_2_id
        )

      %{config1: config1, config2: config2}
    end

    test "create_transaction/2 creates a transaction for a specific clinic", %{config1: _config1} do
      assert {:ok, %Transaction{} = transaction} =
               Paystack.create_transaction(@valid_transaction_attrs, @clinic_1_id)

      assert transaction.clinic_id == @clinic_1_id
      assert transaction.email == @valid_transaction_attrs.email
      assert transaction.amount == @valid_transaction_attrs.amount
    end

    test "list_transactions/1 only returns transactions for the specified clinic", %{
      config1: _config1,
      config2: _config2
    } do
      {:ok, _transaction1} = Paystack.create_transaction(@valid_transaction_attrs, @clinic_1_id)

      {:ok, _transaction2} =
        Paystack.create_transaction(
          Map.put(@valid_transaction_attrs, :reference, "ref_clinic1_2"),
          @clinic_1_id
        )

      {:ok, _transaction3} =
        Paystack.create_transaction(
          Map.put(@valid_transaction_attrs, :reference, "ref_clinic2"),
          @clinic_2_id
        )

      clinic1_transactions = Paystack.list_transactions(@clinic_1_id)
      clinic2_transactions = Paystack.list_transactions(@clinic_2_id)

      assert length(clinic1_transactions) == 2
      assert length(clinic2_transactions) == 1
      assert Enum.all?(clinic1_transactions, fn t -> t.clinic_id == @clinic_1_id end)
      assert Enum.all?(clinic2_transactions, fn t -> t.clinic_id == @clinic_2_id end)
    end

    test "get_transaction/2 only returns a transaction if it belongs to the specified clinic", %{
      config1: _config1,
      config2: _config2
    } do
      {:ok, transaction1} = Paystack.create_transaction(@valid_transaction_attrs, @clinic_1_id)

      {:ok, transaction2} =
        Paystack.create_transaction(
          Map.put(@valid_transaction_attrs, :reference, "ref_clinic2"),
          @clinic_2_id
        )

      # Should be able to get transaction1 with clinic_1_id
      assert {:ok, _fetched_transaction} = Paystack.get_transaction(transaction1.id, @clinic_1_id)

      # Should not be able to get transaction1 with clinic_2_id
      assert {:error, :not_found} = Paystack.get_transaction(transaction1.id, @clinic_2_id)

      # Should be able to get transaction2 with clinic_2_id
      assert {:ok, _fetched_transaction} = Paystack.get_transaction(transaction2.id, @clinic_2_id)

      # Should not be able to get transaction2 with clinic_1_id
      assert {:error, :not_found} = Paystack.get_transaction(transaction2.id, @clinic_1_id)
    end
  end

  describe "transaction reference generation" do
    test "generate_reference/1 creates unique references for different clinics" do
      ref1 = Paystack.generate_reference(@clinic_1_id)
      ref2 = Paystack.generate_reference(@clinic_2_id)

      assert ref1 != ref2
      assert String.contains?(ref1, "#{@clinic_1_id}")
      assert String.contains?(ref2, "#{@clinic_2_id}")
    end

    test "extract_clinic_id_from_reference/1 extracts the correct clinic ID" do
      ref = Paystack.generate_reference(@clinic_1_id)
      assert {:ok, @clinic_1_id} = Paystack.extract_clinic_id_from_reference(ref)

      ref = Paystack.generate_reference(@clinic_2_id)
      assert {:ok, @clinic_2_id} = Paystack.extract_clinic_id_from_reference(ref)
    end
  end

  describe "webhook processing" do
    setup do
      {:ok, config1} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)

      {:ok, config2} =
        Paystack.create_config(
          Map.put(@valid_config_attrs, :name, "Clinic 2 Config"),
          @clinic_2_id
        )

      {:ok, transaction1} = Paystack.create_transaction(@valid_transaction_attrs, @clinic_1_id)

      {:ok, transaction2} =
        Paystack.create_transaction(
          Map.put(@valid_transaction_attrs, :reference, "ref_clinic2"),
          @clinic_2_id
        )

      %{
        config1: config1,
        config2: config2,
        transaction1: transaction1,
        transaction2: transaction2
      }
    end

    test "process_webhook/3 processes webhook for the correct clinic", %{
      transaction1: transaction1
    } do
      webhook_payload = %{
        "event" => "charge.success",
        "data" => %{
          "reference" => transaction1.reference,
          "status" => "success",
          "amount" => transaction1.amount,
          "metadata" => %{
            "clinic_id" => @clinic_1_id
          }
        }
      }

      # Mock signature verification to always succeed for testing
      assert {:ok, _result} =
               Paystack.process_webhook(webhook_payload, @clinic_1_id, ["valid_signature"])

      # The transaction should now be completed
      {:ok, updated_transaction} = Paystack.get_transaction(transaction1.id, @clinic_1_id)
      assert updated_transaction.status == "completed"
    end

    test "process_webhook/3 fails for incorrect clinic", %{transaction1: transaction1} do
      webhook_payload = %{
        "event" => "charge.success",
        "data" => %{
          "reference" => transaction1.reference,
          "status" => "success",
          "amount" => transaction1.amount,
          "metadata" => %{
            "clinic_id" => @clinic_1_id
          }
        }
      }

      # Try to process webhook for clinic 2 with clinic 1's transaction
      assert {:error, :transaction_not_found} =
               Paystack.process_webhook(webhook_payload, @clinic_2_id, ["valid_signature"])
    end
  end
end
