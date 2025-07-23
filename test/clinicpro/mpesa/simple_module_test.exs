defmodule Clinicpro.SimpleModuleTest do
  use ExUnit.Case

  # Test that the modules can be loaded without errors
  test "modules can be loaded" do
    assert Code.ensure_loaded?(Clinicpro.MPesa)
    assert Code.ensure_loaded?(Clinicpro.MPesa.C2B)
    assert Code.ensure_loaded?(Clinicpro.MPesa.MockSTKPush)
    assert Code.ensure_loaded?(Clinicpro.Invoices.PaymentProcessor)
    assert Code.ensure_loaded?(Clinicpro.AdminBypass.Invoice)
  end

  # Test that the modules have the expected functions
  test "modules have expected functions" do
    assert function_exported?(Clinicpro.MPesa.C2B, :process_confirmation, 2)
    assert function_exported?(Clinicpro.MPesa.MockSTKPush, :send_stk_push, 5)
    assert function_exported?(Clinicpro.MPesa.MockSTKPush, :query_stk_push_status, 3)
  end
end
