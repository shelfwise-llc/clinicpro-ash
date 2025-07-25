defmodule ClinicproWeb.InvoiceComponents do
  @moduledoc """
  Provides invoice-specific UI components for the ClinicPro application.
  """
  use Phoenix.Component

  # # import Phoenix.HTML
  # # import Phoenix.HTML.Form
  import PhoenixHTMLHelpers.Tag
  import ClinicproWeb.CoreComponents
  import PhoenixHTMLHelpers.Link

  @doc """
  Renders an invoice item row.
  """
  attr :item, :map, required: true
  attr :class, :string, default: nil

  def invoice_item(assigns) do
    ~H"""
    <div class={["flex justify-between py-2", @class]}>
      <div class="flex-1">
        <p class="text-sm font-medium text-gray-900"><%= @item.description %></p>
        <p :if={@item[:details]} class="text-xs text-gray-500"><%= @item.details %></p>
      </div>
      <div class="text-right">
        <p class="text-sm font-medium text-gray-900"><%= format_currency(@item.amount) %></p>
      </div>
    </div>
    """
  end

  @doc """
  Renders a payment method badge.
  """
  attr :method, :string, required: true
  attr :class, :string, default: nil

  def payment_method_badge(assigns) do
    bg_color =
      case assigns.method do
        "mpesa" -> "bg-green-100 text-green-800"
        "cash" -> "bg-blue-100 text-blue-800"
        "card" -> "bg-purple-100 text-purple-800"
        "insurance" -> "bg-yellow-100 text-yellow-800"
        _ -> "bg-gray-100 text-gray-800"
      end

    assigns = assign(assigns, :bg_color, bg_color)

    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium",
      @bg_color,
      @class
    ]}>
      <%= String.capitalize(@method) %>
    </span>
    """
  end

  @doc """
  Formats a currency amount.
  """
  def format_currency(amount) when is_number(amount) do
    "KES #{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end

  def format_currency(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {num, _} -> format_currency(num)
      :error -> "KES 0.00"
    end
  end

  def format_currency(_), do: "KES 0.00"
end
