defmodule Clinicpro.MPesa.CallbackLogTest do
  use Clinicpro.DataCase

  alias Clinicpro.MPesa.CallbackLog

  @valid_attrs %{
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

  @invalid_attrs %{
    clinic_id: nil,
    type: nil,
    status: nil,
    request_payload: nil
  }

  describe "callback_log" do
    test "create/1 with valid data creates a callback log" do
      assert {:ok, callback_log} = CallbackLog.create(@valid_attrs)
      assert callback_log.clinic_id == 1
      assert callback_log.type == "stk_push"
      assert callback_log.status == "success"
      assert callback_log.reference == "TEST-REF-123"
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CallbackLog.create(@invalid_attrs)
    end

    test "get_by_id_and_clinic/2 returns the callback log with given id and clinic_id" do
      {:ok, callback_log} = CallbackLog.create(@valid_attrs)

      assert CallbackLog.get_by_id_and_clinic(callback_log.id, callback_log.clinic_id) ==
               callback_log

      assert CallbackLog.get_by_id_and_clinic(callback_log.id, 999) == nil
    end

    test "list_by_transaction/2 returns callback logs for a specific transaction" do
      {:ok, callback_log} = CallbackLog.create(@valid_attrs)

      # Create another callback log with a different transaction_id
      {:ok, _other_log} = CallbackLog.create(Map.put(@valid_attrs, :transaction_id, "OTHER-TXN"))

      logs = CallbackLog.list_by_transaction("TEST-TXN-123", 1)
      assert length(logs) == 1
      assert hd(logs).id == callback_log.id
    end

    test "list_by_type/2 returns callback logs for a specific type" do
      {:ok, callback_log} = CallbackLog.create(@valid_attrs)

      # Create another callback log with a different type
      {:ok, _other_log} = CallbackLog.create(Map.put(@valid_attrs, :type, "c2b_validation"))

      logs = CallbackLog.list_by_type("stk_push", 1)
      assert length(logs) == 1
      assert hd(logs).id == callback_log.id
    end

    test "paginate_by_clinic/4 returns paginated callback logs" do
      # Create 25 callback logs
      for i <- 1..25 do
        CallbackLog.create(Map.put(@valid_attrs, :reference, "REF-#{i}"))
      end

      # Test first page (default 20 per page)
      {logs, pagination} = CallbackLog.paginate_by_clinic(1)
      assert length(logs) == 20
      assert pagination.page == 1
      assert pagination.total_pages == 2
      assert pagination.total_count == 25

      # Test second page
      {logs, pagination} = CallbackLog.paginate_by_clinic(1, %{}, 2)
      assert length(logs) == 5
      assert pagination.page == 2

      # Test with smaller per_page
      {logs, pagination} = CallbackLog.paginate_by_clinic(1, %{}, 1, 10)
      assert length(logs) == 10
      assert pagination.total_pages == 3
    end

    test "paginate_by_clinic/4 with filters returns filtered callback logs" do
      # Create callback logs with different types
      {:ok, stk_log} = CallbackLog.create(@valid_attrs)
      {:ok, _c2b_log} = CallbackLog.create(Map.put(@valid_attrs, :type, "c2b_validation"))

      # Test filtering by type
      {logs, _unused} = CallbackLog.paginate_by_clinic(1, %{type: "stk_push"})
      assert length(logs) == 1
      assert hd(logs).id == stk_log.id

      # Test filtering by status
      {logs, _unused} = CallbackLog.paginate_by_clinic(1, %{status: "success"})
      assert length(logs) == 2

      # Test filtering by date
      yesterday = NaiveDateTime.add(NaiveDateTime.utc_now(), -86400)
      tomorrow = NaiveDateTime.add(NaiveDateTime.utc_now(), 86400)

      {logs, _unused} =
        CallbackLog.paginate_by_clinic(1, %{from_date: yesterday, to_date: tomorrow})

      assert length(logs) == 2
    end
  end
end
