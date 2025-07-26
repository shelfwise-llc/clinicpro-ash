defmodule Clinicpro.PaystackWebhookLogTest do
  use Clinicpro.DataCase
  use ClinicproWeb.ConnCase
  import Mock

  alias Clinicpro.Paystack
  alias Clinicpro.Paystack.{Config, Transaction, WebhookLog, Callback}
  alias ClinicproWeb.PaystackAdminController

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
  @valid_transaction_attrs %{
    email: "customer@example.com",
    amount: 1000,
    reference: "test_ref_123",
    description: "Test transaction"
  }
  @valid_webhook_log_attrs %{
    event_type: "charge.success",
    status: "processed",
    payload: %{
      "event" => "charge.success",
      "data" => %{
        "reference" => "test_ref_123",
        "amount" => 1000,
        "status" => "success",
        "customer" => %{
          "email" => "customer@example.com"
        }
      }
    },
    processing_time: 150,
    processing_history: [
      %{
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "status" => "received",
        "message" => "Webhook received"
      },
      %{
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "status" => "processed",
        "message" => "Webhook processed successfully"
      }
    ],
    signature: "test_signature_123"
  }

  setup do
    # Create configs for both clinics
    {:ok, config1} = Paystack.create_config(@valid_config_attrs, @clinic_1_id)

    {:ok, config2} =
      Paystack.create_config(Map.put(@valid_config_attrs, :name, "Clinic 2 Config"), @clinic_2_id)

    # Create transactions for both clinics
    {:ok, transaction1} = Paystack.create_transaction(@valid_transaction_attrs, @clinic_1_id)

    {:ok, transaction2} =
      Paystack.create_transaction(
        Map.put(@valid_transaction_attrs, :reference, "test_ref_456"),
        @clinic_2_id
      )

    # Create webhook logs for both clinics
    {:ok, webhook_log1} =
      WebhookLog.create(
        Map.put(@valid_webhook_log_attrs, :transaction_id, transaction1.id),
        @clinic_1_id
      )

    {:ok, webhook_log2} =
      WebhookLog.create(
        Map.put(@valid_webhook_log_attrs, :transaction_id, transaction2.id)
        |> Map.put(:event_type, "charge.dispute")
        |> Map.put(:status, "failed")
        |> Map.put(:payload, %{
          "event" => "charge.dispute",
          "data" => %{"reference" => "test_ref_456"}
        }),
        @clinic_2_id
      )

    %{
      config1: config1,
      config2: config2,
      transaction1: transaction1,
      transaction2: transaction2,
      webhook_log1: webhook_log1,
      webhook_log2: webhook_log2
    }
  end

  describe "WebhookLog schema" do
    test "list/4 returns webhook logs for a specific clinic with filters", %{
      webhook_log1: webhook_log1
    } do
      # Test without filters
      {logs, count} = WebhookLog.list(@clinic_1_id, %{}, 1, 10)
      assert count == 1
      assert length(logs) == 1
      assert Enum.at(logs, 0).id == webhook_log1.id

      # Test with event_type filter
      {logs, count} = WebhookLog.list(@clinic_1_id, %{event_type: "charge.success"}, 1, 10)
      assert count == 1
      assert length(logs) == 1

      # Test with status filter
      {logs, count} = WebhookLog.list(@clinic_1_id, %{status: "processed"}, 1, 10)
      assert count == 1
      assert length(logs) == 1

      # Test with non-matching filter
      {logs, count} = WebhookLog.list(@clinic_1_id, %{event_type: "non_existing"}, 1, 10)
      assert count == 0
      assert length(logs) == 0
    end

    test "get_with_transaction/2 returns webhook log with transaction for a specific clinic", %{
      webhook_log1: webhook_log1
    } do
      {:ok, fetched_log} = WebhookLog.get_with_transaction(webhook_log1.id, @clinic_1_id)
      assert fetched_log.id == webhook_log1.id
      assert fetched_log.transaction != nil

      # Test with wrong clinic_id
      assert {:error, :not_found} = WebhookLog.get_with_transaction(webhook_log1.id, @clinic_2_id)
    end
  end

  describe "Callback.retry_webhook/2" do
    test "retries a failed webhook for a specific clinic", %{webhook_log2: webhook_log2} do
      # Mock the process_event function to return :ok
      with_mock Callback, process_event: fn _payload, _webhook_log -> :ok end do
        assert {:ok, updated_log} = Callback.retry_webhook(webhook_log2.id, @clinic_2_id)
        assert updated_log.status == "processed"
        assert length(updated_log.processing_history) > length(webhook_log2.processing_history)
      end
    end

    test "returns error when webhook not found" do
      assert {:error, :not_found} = Callback.retry_webhook("non_existing_id", @clinic_1_id)
    end

    test "returns error when webhook is not failed", %{webhook_log1: webhook_log1} do
      assert {:error, :not_failed} = Callback.retry_webhook(webhook_log1.id, @clinic_1_id)
    end

    test "returns error when webhook belongs to different clinic", %{webhook_log2: webhook_log2} do
      assert {:error, :not_found} = Callback.retry_webhook(webhook_log2.id, @clinic_1_id)
    end
  end

  describe "PaystackAdminController webhook actions" do
    setup %{conn: conn} do
      {:ok, conn: conn}
    end

    test "webhook_logs/2 lists webhook logs for a specific clinic", %{conn: conn} do
      conn = get(conn, Routes.paystack_admin_path(conn, :webhook_logs, @clinic_1_id))
      assert html_response(conn, 200) =~ "Webhook Logs"
      assert html_response(conn, 200) =~ "charge.success"
    end

    test "webhook_logs/2 handles filtering", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.paystack_admin_path(conn, :webhook_logs, @clinic_1_id, %{
            "event_type" => "charge.success"
          })
        )

      assert html_response(conn, 200) =~ "charge.success"

      conn =
        get(
          conn,
          Routes.paystack_admin_path(conn, :webhook_logs, @clinic_1_id, %{
            "event_type" => "non_existing"
          })
        )

      assert html_response(conn, 200) =~ "No webhook logs found"
    end

    test "webhook_details/2 shows webhook details for a specific clinic", %{
      conn: conn,
      webhook_log1: webhook_log1
    } do
      conn =
        get(
          conn,
          Routes.paystack_admin_path(conn, :webhook_details, @clinic_1_id, webhook_log1.id)
        )

      assert html_response(conn, 200) =~ "Webhook Details"
      assert html_response(conn, 200) =~ webhook_log1.event_type
    end

    test "webhook_details/2 redirects when webhook not found", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.paystack_admin_path(conn, :webhook_details, @clinic_1_id, "non_existing_id")
        )

      assert redirected_to(conn) == Routes.paystack_admin_path(conn, :webhook_logs, @clinic_1_id)
      assert get_flash(conn, :error) == "Webhook log not found."
    end

    test "retry_webhook/2 retries a failed webhook", %{conn: conn, webhook_log2: webhook_log2} do
      with_mock Callback, retry_webhook: fn _id, _clinic_id -> {:ok, webhook_log2} end do
        conn =
          get(
            conn,
            Routes.paystack_admin_path(conn, :retry_webhook, @clinic_2_id, webhook_log2.id)
          )

        assert redirected_to(conn) ==
                 Routes.paystack_admin_path(conn, :webhook_details, @clinic_2_id, webhook_log2.id)

        assert get_flash(conn, :info) == "Webhook processing retried successfully."
      end
    end

    test "retry_webhook/2 handles retry failure", %{conn: conn, webhook_log2: webhook_log2} do
      with_mock Callback, retry_webhook: fn _id, _clinic_id -> {:error, :some_error} end do
        conn =
          get(
            conn,
            Routes.paystack_admin_path(conn, :retry_webhook, @clinic_2_id, webhook_log2.id)
          )

        assert redirected_to(conn) ==
                 Routes.paystack_admin_path(conn, :webhook_details, @clinic_2_id, webhook_log2.id)

        assert get_flash(conn, :error) =~ "Failed to retry webhook"
      end
    end
  end
end
