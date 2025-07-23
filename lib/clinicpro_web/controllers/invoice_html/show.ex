defmodule ClinicproWeb.InvoiceHTML.Show do
  use ClinicproWeb, :html

  import ClinicproWeb.CoreComponents
  import ClinicproWeb.InvoiceComponents

  embed_templates "show_html/*"

  def invoice_status_badge(assigns) do
    status = assigns[:status] || "pending"

    bg_color = case status do
      "paid" -> "bg-green-100 text-green-800"
      "pending" -> "bg-yellow-100 text-yellow-800"
      "overdue" -> "bg-red-100 text-red-800"
      "cancelled" -> "bg-gray-100 text-gray-800"
      _ -> "bg-blue-100 text-blue-800"
    end

    assigns = assign(assigns, :bg_color, bg_color)

    ~H"""
    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{@bg_color}"}>
      <%= String.capitalize(@status) %>
    </span>
    """
  end

  def payment_section(assigns) do
    ~H"""
    <div class="mt-8 border-t border-gray-200 pt-6">
      <h2 class="text-lg font-medium text-gray-900">Payment Information</h2>

      <div class="mt-4 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <div class="grid grid-cols-1 gap-4">
            <div>
              <h3 class="text-base font-medium text-gray-900">Payment Status</h3>
              <div class="mt-2">
                <%= invoice_status_badge(status: @invoice.payment_status || @invoice.status) %>
              </div>
            </div>

            <%= if @invoice.payment_date do %>
              <div>
                <h3 class="text-base font-medium text-gray-900">Payment Date</h3>
                <div class="mt-2 text-sm text-gray-500">
                  <%= Calendar.strftime(@invoice.payment_date, "%B %d, %Y at %I:%M %p") %>
                </div>
              </div>
            <% end %>

            <%= if @invoice.payment_reference do %>
              <div>
                <h3 class="text-base font-medium text-gray-900">Payment Reference</h3>
                <div class="mt-2 text-sm text-gray-500">
                  <%= @invoice.payment_reference %>
                </div>
              </div>
            <% end %>

            <%= if @invoice.payment_method do %>
              <div>
                <h3 class="text-base font-medium text-gray-900">Payment Method</h3>
                <div class="mt-2 text-sm text-gray-500">
                  <%= String.capitalize(@invoice.payment_method) %>
                </div>
              </div>
            <% end %>

            <%= if @invoice.status != "paid" && @invoice.status != "cancelled" do %>
              <div class="mt-4 border-t border-gray-200 pt-4">
                <h3 class="text-base font-medium text-gray-900">Pay Now</h3>
                <div class="mt-2">
                  <.live_component
                    module={ClinicproWeb.Components.MPesaPaymentButton}
                    id={"mpesa-payment-#{@invoice.id}"}
                    invoice={@invoice}
                    patient={@patient}
                  />
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
