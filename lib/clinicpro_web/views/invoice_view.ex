defmodule ClinicproWeb.InvoiceView do
  use ClinicproWeb, :view

  # Explicitly import required modules
  # # import Phoenix.HTML
  # # import Phoenix.HTML.Form
  # Remove direct import of Phoenix.HTML.Link
  # # # import Phoenix.HTML.Link
  import PhoenixHTMLHelpers.Tag

  # Import phoenix_html_helpers which provides link functions
  import PhoenixHTMLHelpers.Link

  @doc """
  Returns the appropriate CSS class for payment status display.
  """
  def payment_status_color(status) do
    case status do
      :paid -> "text-green-600"
      :partial -> "text-yellow-600"
      :pending -> "text-blue-600"
      :failed -> "text-red-600"
      _ -> "text-gray-600"
    end
  end

  @doc """
  Returns the appropriate CSS class for _transaction status display.
  """
  def transaction_status_color(status) do
    case status do
      "completed" -> "bg-green-100 text-green-800"
      "success" -> "bg-green-100 text-green-800"
      "pending" -> "bg-blue-100 text-blue-800"
      "processing" -> "bg-blue-100 text-blue-800"
      "failed" -> "bg-red-100 text-red-800"
      "cancelled" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  @doc """
  Formats a phone number for display.
  """
  def format_phone_number(nil), do: "-"

  def format_phone_number(phone) do
    # Format phone number as +XXX XXX XXX XXX if it starts with a country code
    if String.starts_with?(phone, "254") do
      "+#{String.slice(phone, 0, 3)} #{String.slice(phone, 3, 3)} #{String.slice(phone, 6, 3)} #{String.slice(phone, 9, 3)}"
    else
      phone
    end
  end

  @doc """
  Formats a date for display.
  """
  def format_date(nil), do: "-"

  def format_date(%DateTime{} = date) do
    Calendar.strftime(date, "%d %b %Y, %H:%M:%S")
  end

  def format_date(%NaiveDateTime{} = date) do
    Calendar.strftime(date, "%d %b %Y, %H:%M:%S")
  end

  def format_date(date), do: date

  @doc """
  Formats an amount for display.
  """
  def format_amount(nil), do: "-"

  def format_amount(amount) when is_float(amount) do
    "KES #{:erlang.float_to_binary(amount, decimals: 2)}"
  end

  def format_amount(amount) when is_integer(amount) do
    "KES #{amount}.00"
  end

  def format_amount(amount), do: "KES #{amount}"

  @doc """
  Returns a human-readable description of the payment status.
  """
  def payment_status_description(status) do
    case status do
      :paid -> "Payment completed"
      :partial -> "Partially paid"
      :pending -> "Payment pending"
      :failed -> "Payment failed"
      _ -> "Unknown status"
    end
  end
end
