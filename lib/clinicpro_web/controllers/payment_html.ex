defmodule ClinicproWeb.PaymentHTML do
  use ClinicproWeb, :html

  embed_templates "payment_html/*"

  @doc """
  Renders the payment _page for an invoice.
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
          <h3 class="text-lg font-semibold mb-2">Pay with M-Pesa</h3>
          <p class="text-sm text-gray-600 mb-4">
            Enter your M-Pesa phone number to receive a payment prompt.
          </p>

          <form id="mpesa-payment-form" phx-submit="none" class="space-y-4">
            <input type="hidden" name="invoice_id" value={@invoice.id} />

            <div>
              <label for="phone" class="block text-sm font-medium text-gray-700 mb-1">
                Phone Number
              </label>
              <input
                type="tel"
                id="phone"
                name="phone"
                placeholder="e.g. 0712345678"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <button
              type="button"
              id="initiate-payment-btn"
              class="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              Pay Now
            </button>
          </form>

          <div id="payment-status" class="mt-4 hidden">
            <div class="flex items-center">
              <div
                id="loading-spinner"
                class="animate-spin rounded-full h-5 w-5 border-b-2 border-green-700 mr-2"
              >
              </div>
              <p id="status-message" class="text-sm text-gray-600">Processing payment...</p>
            </div>
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
      document.addEventListener('DOMContentLoaded', function() {
        const form = document.getElementById('mpesa-payment-form');
        const initiateBtn = document.getElementById('initiate-payment-btn');
        const paymentStatus = document.getElementById('payment-status');
        const statusMessage = document.getElementById('status-message');
        
        if (initiateBtn) {
          initiateBtn.addEventListener('click', function() {
            const phone = document.getElementById('phone').value;
            const invoiceId = form.querySelector('[name="invoice_id"]').value;
            
            if (!phone) {
              alert('Please enter a phone number');
              return;
            }
            
            // Show loading state
            initiateBtn.disabled = true;
            paymentStatus.classList.remove('hidden');
            
            // Make API call to initiate payment
            fetch('/q/payment/mpesa/initiate', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                invoice_id: invoiceId,
                phone: phone
              })
            })
            .then(response => response.json())
            .then(data => {
              if (data.success) {
                statusMessage.textContent = 'Payment request sent. Please check your phone for the STK push.';
                statusMessage.classList.add('text-green-600');
                
                // Start polling for status updates
                pollTransactionStatus(data.transaction_id);
              } else {
                statusMessage.textContent = data.message || 'Payment initiation failed. Please try again.';
                statusMessage.classList.add('text-red-600');
                initiateBtn.disabled = false;
              }
            })
            .catch(error => {
              console.error('Error:', error);
              statusMessage.textContent = 'An error occurred. Please try again.';
              statusMessage.classList.add('text-red-600');
              initiateBtn.disabled = false;
            });
          });
        }
        
        function pollTransactionStatus(transactionId) {
          const interval = setInterval(() => {
            fetch(`/q/payment/mpesa/status/${transactionId}`)
              .then(response => response.json())
              .then(data => {
                if (data.success) {
                  if (data.status === 'completed') {
                    clearInterval(interval);
                    statusMessage.textContent = 'Payment successful! Redirecting...';
                    statusMessage.classList.remove('text-red-600');
                    statusMessage.classList.add('text-green-600');
                    
                    // Redirect to success _page or reload to show updated status
                    setTimeout(() => {
                      window.location.reload();
                    }, 2000);
                  } else if (data.status === 'failed') {
                    clearInterval(interval);
                    statusMessage.textContent = `Payment failed: ${data.result_desc || 'Unknown error'}`;
                    statusMessage.classList.add('text-red-600');
                    initiateBtn.disabled = false;
                  }
                  // Continue polling for 'pending' status
                }
              })
              .catch(error => {
                console.error('Error polling status:', error);
              });
          }, 5000); // Poll every 5 seconds
          
          // Stop polling after 2 minutes (24 attempts)
          setTimeout(() => {
            clearInterval(interval);
            if (!statusMessage.classList.contains('text-green-600')) {
              statusMessage.textContent = 'Payment status check timed out. Please check your M-Pesa app or SMS for confirmation.';
              initiateBtn.disabled = false;
            }
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
