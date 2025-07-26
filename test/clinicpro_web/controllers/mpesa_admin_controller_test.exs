defmodule ClinicproWeb.MPesaAdminControllerTest do
  use ClinicproWeb.ConnCase, async: true

  alias Clinicpro.MPesa.Config
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.MPesa.CallbackLog
  alias Clinicpro.Accounts

  @valid_config_attrs %{
    clinic_id: 1,
    consumer_key: "test_key",
    consumer_secret: "test_secret",
    passkey: "test_passkey",
    shortcode: "174379",
    environment: "sandbox",
    base_url: "https://sandbox.safaricom.co.ke",
    callback_url: "https://example.com/callback",
    validation_url: "https://example.com/validation",
    confirmation_url: "https://example.com/confirmation",
    active: true
  }

  @valid_transaction_attrs %{
    clinic_id: 1,
    invoice_id: 1,
    patient_id: 1,
    phone_number: "254712345678",
    amount: 1000.0,
    status: "pending",
    reference: "TEST-REF-123",
    checkout_request_id: "ws_CO_123456789",
    merchant_request_id: "123-456-789"
  }

  @valid_callback_log_attrs %{
    clinic_id: 1,
    type: "stk_push",
    status: "success",
    reference: "TEST-REF-123",
    shortcode: "174379",
    url: "https://example.com/callback",
    request_payload: "{\"test\":\"payload\"}",
    response_payload: "{\"result\":\"success\"}",
    response_code: "0",
    response_description: "Success",
    processing_time: 120,
    transaction_id: "TEST-TXN-123"
  }

  setup %{conn: conn} do
    # Create a user with admin role
    {:ok, user} =
      Accounts.register_admin(%{
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123",
        clinic_id: 1,
        role: "admin"
      })

    # Create a config for testing
    {:ok, config} = Config.create(@valid_config_attrs)

    # Create a transaction for testing
    {:ok, transaction} = Transaction.create(@valid_transaction_attrs)

    # Create a callback log for testing
    {:ok, callback_log} = CallbackLog.create(@valid_callback_log_attrs)

    # Log in the user
    conn = log_in_user(conn, user)

    {:ok,
     conn: conn, user: user, config: config, transaction: transaction, callback_log: callback_log}
  end

  describe "index" do
    test "lists all M-Pesa transactions", %{conn: conn} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa")
      assert html_response(conn, 200) =~ "M-Pesa Transactions"
    end
  end

  describe "show transaction" do
    test "displays transaction details", %{conn: conn, transaction: transaction} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/transactions/#{transaction.id}")
      assert html_response(conn, 200) =~ "Transaction Details"
      assert html_response(conn, 200) =~ transaction.reference
    end

    test "returns error for transaction not found", %{conn: conn} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/transactions/999999")
      assert redirected_to(conn) == ~p"/admin/clinics/1/mpesa"
      assert get_flash(conn, :error) =~ "Transaction not found"
    end
  end

  describe "configuration" do
    test "displays configuration details", %{conn: conn, config: config} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/config")
      assert html_response(conn, 200) =~ "M-Pesa Configuration"
      assert html_response(conn, 200) =~ config.shortcode
    end

    test "updates configuration", %{conn: conn, config: config} do
      conn =
        put(conn, ~p"/admin/clinics/1/mpesa/config/#{config.id}", %{
          "config" => %{"shortcode" => "654321"}
        })

      assert redirected_to(conn) == ~p"/admin/clinics/1/mpesa/config"
      assert get_flash(conn, :info) =~ "Configuration updated successfully"

      # Verify the update
      updated_config = Config.get_by_id(config.id)
      assert updated_config.shortcode == "654321"
    end

    test "activates configuration", %{conn: conn, config: config} do
      # First deactivate the config
      {:ok, _unused} = Config.deactivate(config.id)

      conn = put(conn, ~p"/admin/clinics/1/mpesa/config/#{config.id}/activate")
      assert redirected_to(conn) == ~p"/admin/clinics/1/mpesa/config"
      assert get_flash(conn, :info) =~ "Configuration activated successfully"

      # Verify the activation
      updated_config = Config.get_by_id(config.id)
      assert updated_config.active == true
    end

    test "deactivates configuration", %{conn: conn, config: config} do
      conn = put(conn, ~p"/admin/clinics/1/mpesa/config/#{config.id}/deactivate")
      assert redirected_to(conn) == ~p"/admin/clinics/1/mpesa/config"
      assert get_flash(conn, :info) =~ "Configuration deactivated successfully"

      # Verify the deactivation
      updated_config = Config.get_by_id(config.id)
      assert updated_config.active == false
    end
  end

  describe "callback logs" do
    test "lists all callback logs", %{conn: conn} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/callbacks")
      assert html_response(conn, 200) =~ "Callback Logs"
    end

    test "displays callback log details", %{conn: conn, callback_log: callback_log} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/callbacks/#{callback_log.id}")
      assert html_response(conn, 200) =~ "Callback Details"
      assert html_response(conn, 200) =~ callback_log.reference
    end

    test "returns error for callback log not found", %{conn: conn} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/callbacks/999999")
      assert redirected_to(conn) == ~p"/admin/clinics/1/mpesa/callbacks"
      assert get_flash(conn, :error) =~ "Callback log not found"
    end
  end

  describe "stk push test" do
    test "displays stk push test form", %{conn: conn} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/stk-push-test")
      assert html_response(conn, 200) =~ "STK Push Test"
    end

    test "initiates stk push test", %{conn: conn} do
      # Mock the STK Push initiation - this would normally be handled by a mock
      # For this test, we'll just check that the controller handles the form submission
      conn =
        post(conn, ~p"/admin/clinics/1/mpesa/stk-push-test", %{
          "stk_push" => %{
            "phone_number" => "254712345678",
            "amount" => "10",
            "reference" => "TEST-REF"
          }
        })

      # In a real test with mocks, we'd verify the STK Push was initiated
      # Here we just check that the controller handled the submission
      assert html_response(conn, 200) =~ "STK Push Test"
    end
  end

  describe "register callback url" do
    test "displays register callback url form", %{conn: conn} do
      conn = get(conn, ~p"/admin/clinics/1/mpesa/register-url")
      assert html_response(conn, 200) =~ "Register Callback URL"
    end

    test "registers callback url", %{conn: conn} do
      # Mock the URL registration - this would normally be handled by a mock
      # For this test, we'll just check that the controller handles the form submission
      conn = post(conn, ~p"/admin/clinics/1/mpesa/register-url", %{})

      # In a real test with mocks, we'd verify the URL was registered
      # Here we just check that the controller handled the submission
      assert html_response(conn, 200) =~ "Register Callback URL"
    end
  end

  # Helper function to log in a user for testing
  defp log_in_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_id, user.id)
    |> Plug.Conn.put_session(:live_socket_id, "users_sessions:#{user.id}")
  end
end
