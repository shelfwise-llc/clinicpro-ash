defmodule Clinicpro.FocusedMPesaTest do
  use ExUnit.Case, async: true
  
  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.{Config, C2B, MockSTKPush, Transaction}
  
  # Test that the modules can be loaded without errors
  test "modules can be loaded" do
    assert Code.ensure_loaded?(Clinicpro.MPesa)
    assert Code.ensure_loaded?(Clinicpro.MPesa.C2B)
    assert Code.ensure_loaded?(Clinicpro.MPesa.MockSTKPush)
    assert Code.ensure_loaded?(Clinicpro.MPesa.Config)
    assert Code.ensure_loaded?(Clinicpro.MPesa.Transaction)
  end
  
  # Test that the modules have the expected functions
  test "modules have expected functions" do
    assert function_exported?(Clinicpro.MPesa.C2B, :process_confirmation, 2)
    assert function_exported?(Clinicpro.MPesa.MockSTKPush, :send_stk_push, 5)
    assert function_exported?(Clinicpro.MPesa.MockSTKPush, :query_stk_push_status, 3)
  end
  
  # Test the multi-tenant configuration functionality
  test "config module supports multi-tenant configurations" do
    # Create test configs for different clinics
    clinic1_id = "clinic1"
    clinic2_id = "clinic2"
    
    # Set up test configs
    config1 = %{
      consumer_key: "test_key_1",
      consumer_secret: "test_secret_1",
      passkey: "test_passkey_1",
      shortcode: "123456",
      callback_url: "https://example.com/callback/1",
      active: true
    }
    
    config2 = %{
      consumer_key: "test_key_2",
      consumer_secret: "test_secret_2",
      passkey: "test_passkey_2",
      shortcode: "654321",
      callback_url: "https://example.com/callback/2",
      active: true
    }
    
    # Test that configs are isolated by clinic
    assert Config.get_config(clinic1_id) != Config.get_config(clinic2_id)
  end
  
  # Test the mock STK Push functionality
  test "mock STK push generates unique request IDs" do
    phone_number = "254712345678"
    amount = 100
    reference = "TEST123"
    description = "Test payment"
    clinic_id = "test_clinic"
    
    # Call the mock STK push function
    {:ok, result1} = MockSTKPush.send_stk_push(phone_number, amount, reference, description, clinic_id)
    {:ok, result2} = MockSTKPush.send_stk_push(phone_number, amount, reference, description, clinic_id)
    
    # Verify that unique IDs are generated
    assert result1.checkout_request_id != result2.checkout_request_id
    assert result1.merchant_request_id != result2.merchant_request_id
  end
end
