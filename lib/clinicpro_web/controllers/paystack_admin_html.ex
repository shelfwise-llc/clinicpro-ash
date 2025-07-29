defmodule ClinicproWeb.PaystackAdminHTML do
  use Phoenix.Component
  use ClinicproWeb, :html

  # Embed all templates
  embed_templates "paystack_admin_html/*"

  # Re-export form helpers for use in templates
  def checkbox(form, field, opts \\ []), do: Phoenix.HTML.Form.checkbox(form, field, opts)
  def text_input(form, field, opts \\ []), do: Phoenix.HTML.Form.text_input(form, field, opts)

  def password_input(form, field, opts \\ []),
    do: Phoenix.HTML.Form.password_input(form, field, opts)

  def textarea(form, field, opts \\ []), do: Phoenix.HTML.Form.textarea(form, field, opts)

  def select(form, field, options, opts \\ []),
    do: Phoenix.HTML.Form.select(form, field, options, opts)

  def label(form, field, text \\ nil, opts \\ []),
    do: Phoenix.HTML.Form.label(form, field, text, opts)

  def number_input(form, field, opts \\ []),
    do: Phoenix.HTML.Form.number_input(form, field, opts)

  def email_input(form, field, opts \\ []), do: Phoenix.HTML.Form.email_input(form, field, opts)
  def submit(value, opts \\ []), do: Phoenix.HTML.Form.submit(value, opts)
  def error_tag(form, field), do: ClinicproWeb.ErrorHelpers.error_tag(form, field)
  def link(text, opts), do: Phoenix.HTML.Link.link(text, opts)

  # String masking and formatting functions
  def mask_string(nil), do: "-"

  def mask_string(string) when is_binary(string) do
    if String.length(string) > 4 do
      first_chars = String.slice(string, 0, 2)
      last_chars = String.slice(string, -2, 2)
      middle_chars = String.duplicate("*", String.length(string) - 4)
      first_chars <> middle_chars <> last_chars
    else
      string
    end
  end

  def mask_string(_unused), do: "-"

  def mask_sensitive(nil), do: nil

  def mask_sensitive(string) when is_binary(string) do
    if String.length(string) > 4 do
      masked_part = String.duplicate("*", String.length(string) - 4)
      masked_part <> String.slice(string, -4..-1)
    else
      string
    end
  end

  # Amount formatting
  def format_amount(amount) when is_integer(amount) do
    amount_naira = amount / 100
    :erlang.float_to_binary(amount_naira, decimals: 2)
  end

  def format_amount(nil), do: "0.00"

  def format_amount(amount) when is_float(amount),
    do: :erlang.float_to_binary(amount, decimals: 2)

  def format_amount(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {float, _unused} -> :erlang.float_to_binary(float, decimals: 2)
      :error -> "0.00"
    end
  end

  def format_money(nil), do: "0.00"

  def format_money(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {float_amount, _unused} -> format_money(float_amount)
      :error -> "0.00"
    end
  end

  def format_money(amount) when is_integer(amount) do
    amount
    |> Kernel./(100)
    |> Float.round(2)
    |> :erlang.float_to_binary([{:decimals, 2}])
  end

  def format_money(amount) when is_float(amount) do
    amount
    |> Float.round(2)
    |> :erlang.float_to_binary([{:decimals, 2}])
  end

  def format_money(_unused), do: "0.00"

  # Date formatting
  def format_date(nil), do: "-"

  def format_date(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%B %d, %Y %H:%M")
  end

  def format_date(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> format_date()
  end

  def format_date(date) do
    case Date.from_iso8601(date) do
      {:ok, d} ->
        Calendar.strftime(d, "%Y-%m-%d")

      _unused ->
        date
    end
  end

  def format_datetime(nil), do: "-"

  def format_datetime(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _unused} ->
        Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")

      _unused ->
        case NaiveDateTime.from_iso8601(datetime) do
          {:ok, ndt} ->
            Calendar.strftime(ndt, "%Y-%m-%d %H:%M:%S")

          _unused ->
            datetime
        end
    end
  end

  # Status formatting helpers
  def status_class("completed"), do: "text-green-600"
  def status_class("pending"), do: "text-yellow-600"
  def status_class("failed"), do: "text-red-600"
  def status_class(_unused), do: "text-gray-600"

  def humanize_status("completed"), do: "Completed"
  def humanize_status("pending"), do: "Pending"
  def humanize_status("failed"), do: "Failed"
  def humanize_status(status), do: status

  def webhook_status_class("processed"), do: "bg-green-100 text-green-800"
  def webhook_status_class("failed"), do: "bg-red-100 text-red-800"
  def webhook_status_class("pending"), do: "bg-yellow-100 text-yellow-800"
  def webhook_status_class(_unused), do: "bg-gray-100 text-gray-800"

  def webhook_status_badge("processed"), do: "bg-green-100 text-green-800"
  def webhook_status_badge("failed"), do: "bg-red-100 text-red-800"
  def webhook_status_badge("pending"), do: "bg-yellow-100 text-yellow-800"
  def webhook_status_badge(_unused), do: "bg-gray-100 text-gray-800"

  def humanize_webhook_status("processed"), do: "Processed"
  def humanize_webhook_status("failed"), do: "Failed"
  def humanize_webhook_status("pending"), do: "Pending"
  def humanize_webhook_status(status), do: status

  # Time and JSON formatting
  def format_processing_time(nil), do: "-"
  def format_processing_time(time) when time < 1000, do: "#{time} ms"
  def format_processing_time(time), do: "#{time / 1000} s"

  def format_json(nil), do: "-"

  def format_json(payload) when is_map(payload) do
    Jason.encode!(payload, pretty: true)
  end

  def format_json(payload) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, decoded} -> Jason.encode!(decoded, pretty: true)
      _unused -> payload
    end
  end
end
