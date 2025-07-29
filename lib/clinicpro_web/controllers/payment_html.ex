defmodule ClinicproWeb.PaymentHTML do
  use ClinicproWeb, :html

  embed_templates "payment_html/*"

  @doc """
  Renders the payment page for an invoice.
  """
  def show(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 class="text-2xl font-bold mb-6 text-gray-800">Payment Details</h1>

      <div class="mb-6 p-4 border rounded-md bg-gray-50">
        <h2 class="text-lg font-semibold mb-2">Invoice #<%= @invoice.reference_number %></h2>
        <div class="grid grid-cols-2 gap-2">
          <div class="text-gray-600">Description:</div>
          <div><%= @invoice.description %></div>

          <div class="text-gray-600">Amount:</div>
          <div class="font-semibold">
            KES <%= :erlang.float_to_binary(@invoice.amount, decimals: 2) %>
          </div>

          <div class="text-gray-600">Status:</div>
          <div class={status_color(@invoice.status)}>
            <%= String.capitalize(@invoice.status) %>
          </div>
        </div>
      </div>

      <%= if @invoice.status == "unpaid" do %>
        <div class="mb-6">
          <h3 class="text-lg font-semibold mb-2">Pay with Paystack</h3>
          <p class="text-sm text-gray-600 mb-4">
            Payment processing is handled through Paystack.
          </p>

          <div class="mt-4">
            <p class="text-sm text-gray-600">Payment integration is being set up. Please check back later.</p>
          </div>
        </div>
      <% end %>

      <div class="mt-6">
        <a href="/patient/dashboard" class="text-blue-600 hover:underline">
          Back to Dashboard
        </a>
      </div>
    </div>

    <script>
      // Payment processing handled through Paystack integration
          }, 120000);
        }
      });
    </script>
    """
  end

  # Helper function to set status color
  defp status_color(status) do
    case status do
      "paid" -> "text-green-600 font-semibold"
      "pending" -> "text-yellow-600 font-semibold"
      "unpaid" -> "text-red-600 font-semibold"
      _unused -> "text-gray-600"
    end
  end
end
