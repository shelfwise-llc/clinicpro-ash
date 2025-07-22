defmodule Clinicpro.MPesaMultiClinicTest do
  use Clinicpro.DataCase

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, Transaction}
  alias Clinicpro.AdminBypass.Doctor

  # Helper functions for test setup
  defp create_test_clinic(name, email) do
    Doctor.create(%{name: name, email: email})
  end

  defp create_mpesa_config(clinic_id, shortcode) do
    MPesa.create_config(%{
      clinic_id: clinic_id,
      consumer_key: "test_key_#{clinic_id}",
      consumer_secret: "test_secret_#{clinic_id}",
      passkey: "test_passkey_#{clinic_id}",
      shortcode: shortcode,
      environment: "sandbox"
    })
  end

  setup do
    # Create test clinics
    {:ok, clinic1} = create_test_clinic("Test Clinic 1", "clinic1@example.com")
    {:ok, clinic2} = create_test_clinic("Test Clinic 2", "clinic2@example.com")
    
    # Create M-Pesa configs for both clinics
    {:ok, _config1} = create_mpesa_config(clinic1.id, "123456")
    {:ok, _config2} = create_mpesa_config(clinic2.id, "654321")
    
    # Return test data
    %{clinic1: clinic1, clinic2: clinic2}
  end

  describe "multi-tenant configuration" do
    test "each clinic has its own M-Pesa configuration", %{clinic1: clinic1, clinic2: clinic2} do
      {:ok, config1} = Config.get_for_clinic(clinic1.id)
      {:ok, config2} = Config.get_for_clinic(clinic2.id)
      
      assert config1.consumer_key != config2.consumer_key
      assert config1.shortcode != config2.shortcode
      assert config1.clinic_id == clinic1.id
      assert config2.clinic_id == clinic2.id
    end
    
    test "returns error when config not found" do
      assert {:error, :config_not_found} = Config.get_for_clinic(999)
    end
  end

  describe "transaction isolation" do
    test "transactions are isolated by clinic", %{clinic1: clinic1, clinic2: clinic2} do
      # Create transactions for clinic1
      {:ok, _} = Transaction.create_pending(%{
        clinic_id: clinic1.id,
        phone: "254712345678",
        amount: 100,
        reference: "CLINIC1-1",
        type: "stk_push"
      })
      
      {:ok, _} = Transaction.create_pending(%{
        clinic_id: clinic1.id,
        phone: "254712345678",
        amount: 200,
        reference: "CLINIC1-2",
        type: "stk_push"
      })
      
      # Create transaction for clinic2
      {:ok, _} = Transaction.create_pending(%{
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
      
      # Verify clinic1 can't see clinic2's transactions
      for tx <- transactions1 do
        assert tx.clinic_id == clinic1.id
      end
      
      # Verify clinic2 can't see clinic1's transactions
      for tx <- transactions2 do
        assert tx.clinic_id == clinic2.id
      end
    end
  end

  describe "transaction statistics" do
    test "statistics are isolated by clinic", %{clinic1: clinic1, clinic2: clinic2} do
      # Create completed transaction for clinic1
      {:ok, tx1} = Transaction.create_pending(%{
        clinic_id: clinic1.id,
        phone: "254712345678",
        amount: 100,
        reference: "CLINIC1-COMPLETE",
        type: "stk_push"
      })
      Transaction.update(tx1, %{status: "completed"})
      
      # Create pending transaction for clinic1
      {:ok, _} = Transaction.create_pending(%{
        clinic_id: clinic1.id,
        phone: "254712345678",
        amount: 200,
        reference: "CLINIC1-PENDING",
        type: "stk_push"
      })
      
      # Create completed transaction for clinic2
      {:ok, tx2} = Transaction.create_pending(%{
        clinic_id: clinic2.id,
        phone: "254712345678",
        amount: 300,
        reference: "CLINIC2-COMPLETE",
        type: "stk_push"
      })
      Transaction.update(tx2, %{status: "completed"})
      
      # Get statistics for clinic1
      stats1 = Transaction.get_stats_for_clinic(clinic1.id)
      assert stats1.total_count == 2
      assert stats1.completed_count == 1
      assert stats1.pending_count == 1
      
      # Get statistics for clinic2
      stats2 = Transaction.get_stats_for_clinic(clinic2.id)
      assert stats2.total_count == 1
      assert stats2.completed_count == 1
      assert stats2.pending_count == 0
      
      # Verify total amounts are isolated
      assert stats1.total_amount != stats2.total_amount
    end
  end
end
