defmodule ClinicproWeb.PaystackAdminHTMLTest do
  use ClinicproWeb.ConnCase, async: true
  alias ClinicproWeb.PaystackAdminHTML

  describe "webhook log helpers" do
    test "webhook_status_badge/1 returns correct badge classes" do
      assert PaystackAdminHTML.webhook_status_badge("processed") =~ "bg-green-100 text-green-800"
      assert PaystackAdminHTML.webhook_status_badge("failed") =~ "bg-red-100 text-red-800"
      assert PaystackAdminHTML.webhook_status_badge("pending") =~ "bg-yellow-100 text-yellow-800"
      assert PaystackAdminHTML.webhook_status_badge("unknown") =~ "bg-gray-100 text-gray-800"
    end

    test "humanize_webhook_status/1 returns human-friendly status" do
      assert PaystackAdminHTML.humanize_webhook_status("processed") == "Processed"
      assert PaystackAdminHTML.humanize_webhook_status("failed") == "Failed"
      assert PaystackAdminHTML.humanize_webhook_status("pending") == "Pending"
      assert PaystackAdminHTML.humanize_webhook_status("unknown") == "Unknown"
    end

    test "format_processing_time/1 formats processing time correctly" do
      assert PaystackAdminHTML.format_processing_time(123) == "123ms"
      assert PaystackAdminHTML.format_processing_time(1500) == "1.5s"
      assert PaystackAdminHTML.format_processing_time(nil) == "-"
    end

    test "format_json/1 formats JSON for display" do
      json = %{"event" => "charge.success", "data" => %{"amount" => 1000}}
      formatted = PaystackAdminHTML.format_json(json)

      assert formatted =~ "{\n"
      assert formatted =~ "\"event\": \"charge.success\""
      assert formatted =~ "\"data\": {\n"
      assert formatted =~ "\"amount\": 1000"
    end
  end
end
