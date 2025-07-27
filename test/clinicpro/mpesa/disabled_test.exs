defmodule Clinicpro.MPesaDisabledTest do
  use Clinicpro.DataCase

  alias Clinicpro.MPesa

  describe "disabled MPesa module" do
    test "initiate_stk_push returns error tuple" do
      result = MPesa.initiate_stk_push("254712345678", 100, "Test payment", "test-ref", "clinic-123")
      assert {:error, :mpesa_disabled} = result
    end

    test "check_stk_push_status returns error tuple" do
      result = MPesa.check_stk_push_status("checkout-id", "clinic-123")
      assert {:error, :mpesa_disabled} = result
    end

    test "process_stk_callback returns error tuple" do
      result = MPesa.process_stk_callback(%{"Body" => %{}}, "clinic-123")
      assert {:error, :mpesa_disabled} = result
    end

    test "get_transaction returns error tuple" do
      result = MPesa.get_transaction("transaction-id", "clinic-123")
      assert {:error, :mpesa_disabled} = result
    end

    test "list_transactions returns empty list" do
      result = MPesa.list_transactions("clinic-123")
      assert [] = result
    end

    test "update_config returns error tuple" do
      result = MPesa.update_config(%{}, "clinic-123")
      assert {:error, :mpesa_disabled} = result
    end

    test "get_config returns error tuple" do
      result = MPesa.get_config("clinic-123")
      assert {:error, :mpesa_disabled} = result
    end

    test "register_c2b_urls returns error tuple" do
      result = MPesa.register_c2b_urls("clinic-123")
      assert {:error, :mpesa_disabled} = result
    end

    test "process_c2b_callback returns error tuple" do
      result = MPesa.process_c2b_callback(%{}, "clinic-123")
      assert {:error, :mpesa_disabled} = result
    end
  end
end
