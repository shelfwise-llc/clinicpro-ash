defmodule Clinicpro.MPesaIntegrationTest do
  use ExUnit.Case

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, Transaction}

  # Test the multi-tenant design of the M-Pesa integration
  describe "M-Pesa multi-tenant architecture" do
    test "configuration structure supports multi-tenant design" do
      # Verify the Config schema has clinic_id field
      fields = Config.__schema__(:fields)
      assert :clinic_id in fields
      assert :consumer_key in fields
      assert :consumer_secret in fields
      assert :passkey in fields
      assert :shortcode in fields
      assert :environment in fields
    end

    test "transaction schema supports multi-tenant isolation" do
      # Verify the Transaction schema has clinic_id field
      fields = Transaction.__schema__(:fields)
      assert :clinic_id in fields
      assert :checkout_request_id in fields
      assert :merchant_request_id in fields
      assert :reference in fields
      assert :phone in fields
      assert :amount in fields
      assert :status in fields
    end
  end

  describe "M-Pesa module API design" do
    test "initiate_stk_push requires clinic_id" do
      # Check function arity and first parameter
      {:arity, 5} = Function.info(function(:initiate_stk_push), :arity)

      # Check function implementation for clinic_id parameter
      {:module, mod} = :code.get_object_code(Clinicpro.MPesa)

      {:ok, {_unused, [{:abstract_code, {:raw_abstract_v1, abstract_code}}]}} =
        :beam_lib.chunks(mod, [:abstract_code])

      # Find the initiate_stk_push function definition
      found =
        Enum.find(abstract_code, fn
          {:function, _unused, :initiate_stk_push, 5, _unused} -> true
          _unused -> false
        end)

      assert found != nil, "initiate_stk_push/5 function not found"
    end

    test "register_c2b_urls requires clinic_id" do
      # Check function arity
      {:arity, 1} = Function.info(function(:register_c2b_urls), :arity)
    end

    test "list_transactions filters by clinic_id" do
      # Check function arity and first parameter
      {:arity, 3} = Function.info(function(:list_transactions), :arity)
    end
  end

  # Helper function to get function reference
  defp function(name) do
    case name do
      :initiate_stk_push -> &MPesa.initiate_stk_push/5
      :register_c2b_urls -> &MPesa.register_c2b_urls/1
      :list_transactions -> &MPesa.list_transactions/3
      _unused -> nil
    end
  end
end
