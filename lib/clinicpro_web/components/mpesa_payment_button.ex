defmodule ClinicproWeb.Components.MPesaPaymentButton do
  @moduledoc """
  LiveView component for initiating M-Pesa STK push payments from the invoice UI.
  Supports multi-tenant architecture with clinic-specific configurations.
  """

  use ClinicproWeb, :live_component

  alias Clinicpro.Invoices.PaymentProcessor
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"mpesa-payment-#{@id}"} class="w-full">
      <div class="flex flex-col space-y-4">
        <%= if @payment_status == "initiated" do %>
          <div class="bg-blue-50 border border-blue-200 rounded-md p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-blue-400"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3 flex-1 md:flex md:justify-between">
                <p class="text-sm text-blue-700">
                  Please check your phone for the M-Pesa payment request.
                </p>
                <p class="mt-3 text-sm md:mt-0 md:ml-6">
                  <button
                    phx-click={JS.push("check_payment_status", target: @myself)}
                    class="whitespace-nowrap font-medium text-blue-700 hover:text-blue-600"
                  >
                    Check Status <span aria-hidden="true">&rarr;</span>
                  </button>
                </p>
              </div>
            </div>
          </div>
        <% end %>

        <%= if @payment_status == "failed" do %>
          <div class="bg-red-50 border border-red-200 rounded-md p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-red-400"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">Payment Failed</h3>
                <div class="mt-2 text-sm text-red-700">
                  <p>
                    <%= @error_message ||
                      "There was an error processing your payment. Please try again." %>
                  </p>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <%= if @payment_status == "completed" do %>
          <div class="bg-green-50 border border-green-200 rounded-md p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-green-400"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-green-800">Payment Successful</h3>
                <div class="mt-2 text-sm text-green-700">
                  <p>
                    Your payment has been processed successfully. Reference: <%= @payment_reference %>
                  </p>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <%= if @payment_status != "completed" do %>
          <div class="mt-2">
            <label for={"phone-number-#{@id}"} class="block text-sm font-medium text-gray-700">
              Phone Number (for M-Pesa)
            </label>
            <div class="mt-1 relative rounded-md shadow-sm">
              <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                <span class="text-gray-500 sm:text-sm">+</span>
              </div>
              <input
                type="tel"
                name="phone_number"
                id={"phone-number-#{@id}"}
                class="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-7 pr-12 sm:text-sm border-gray-300 rounded-md"
                placeholder="254712345678"
                value={@phone_number}
                phx-keyup="validate_phone"
                phx-target={@myself}
                phx-debounce="500"
                disabled={@payment_status == "initiated"}
              />
              <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                <span class="text-gray-500 sm:text-sm" id="phone-number-addon">
                  M-Pesa
                </span>
              </div>
            </div>
            <%= if @phone_error do %>
              <p class="mt-2 text-sm text-red-600" id={"phone-error-#{@id}"}><%= @phone_error %></p>
            <% end %>
          </div>

          <div class="mt-4">
            <button
              type="button"
              phx-click="initiate_payment"
              phx-target={@myself}
              disabled={@payment_status == "initiated" || @phone_error != nil || @phone_number == ""}
              class={[
                "w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white",
                if(@payment_status == "initiated" || @phone_error != nil || @phone_number == "",
                  do: "bg-indigo-300 cursor-not-allowed",
                  else:
                    "bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                )
              ]}
            >
              <%= if @payment_status == "initiated" do %>
                <svg
                  class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  >
                  </circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  >
                  </path>
                </svg>
                Processing...
              <% else %>
                <svg
                  class="-ml-1 mr-2 h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                Pay with M-Pesa
              <% end %>
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:payment_status, "pending")
     |> assign(:phone_number, "")
     |> assign(:phone_error, nil)
     |> assign(:error_message, nil)
     |> assign(:payment_reference, nil)}
  end

  @impl true
  def update(%{invoice: invoice} = assigns, socket) do
    # Initialize the component with the invoice data
    socket =
      socket
      |> assign(assigns)
      |> assign(:payment_status, get_payment_status(invoice))
      |> assign(:payment_reference, invoice.payment_reference)
      |> assign(:error_message, invoice.payment_error)
      |> maybe_prefill_phone_number(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_phone", %{"value" => phone_number}, socket) do
    # Validate the phone number format
    error =
      case validate_phone_number(phone_number) do
        :ok -> nil
        {:error, message} -> message
      end

    {:noreply, assign(socket, phone_number: phone_number, phone_error: error)}
  end

  @impl true
  def handle_event("initiate_payment", _params, socket) do
    %{invoice: invoice, phone_number: phone_number} = socket.assigns

    # Initiate the M-Pesa payment
    case PaymentProcessor.initiate_payment(invoice, phone_number) do
      {:ok, _response} ->
        # Update the UI to show the payment is initiated
        {:noreply,
         socket
         |> assign(:payment_status, "initiated")
         |> assign(:error_message, nil)}

      {:error, reason} ->
        # Show the error message
        error_message = format_error_message(reason)

        {:noreply,
         socket
         |> assign(:payment_status, "failed")
         |> assign(:error_message, error_message)}
    end
  end

  @impl true
  def handle_event("check_payment_status", _params, socket) do
    %{invoice: invoice} = socket.assigns

    # Check the current payment status
    case PaymentProcessor.check_payment_status(invoice) do
      {:ok, :completed} ->
        # Refresh the invoice data to get the latest status
        updated_invoice = Clinicpro.Invoices.get_invoice(invoice.id)

        {:noreply,
         socket
         |> assign(:payment_status, "completed")
         |> assign(:invoice, updated_invoice)
         |> assign(:payment_reference, updated_invoice.payment_reference)}

      {:ok, :pending} ->
        # Still waiting for payment
        {:noreply, socket}

      {:ok, :failed} ->
        # Payment failed
        updated_invoice = Clinicpro.Invoices.get_invoice(invoice.id)

        {:noreply,
         socket
         |> assign(:payment_status, "failed")
         |> assign(:invoice, updated_invoice)
         |> assign(:error_message, updated_invoice.payment_error || "Payment failed")}

      {:ok, :no_transaction} ->
        # No _transaction found
        {:noreply,
         socket
         |> assign(:payment_status, "pending")}

      {:error, reason} ->
        # Error checking status
        {:noreply,
         socket
         |> assign(:error_message, format_error_message(reason))}
    end
  end

  # Private functions

  defp get_payment_status(invoice) do
    case invoice.payment_status do
      "completed" -> "completed"
      "payment_initiated" -> "initiated"
      "payment_failed" -> "failed"
      _unused -> "pending"
    end
  end

  defp maybe_prefill_phone_number(socket, %{patient: patient}) when not is_nil(patient) do
    # If we have a patient, prefill their phone number
    if patient.phone_number && patient.phone_number != "" do
      assign(socket, :phone_number, patient.phone_number)
    else
      socket
    end
  end

  defp maybe_prefill_phone_number(socket, _assigns), do: socket

  defp validate_phone_number(phone_number) do
    # Remove any non-digit characters
    digits_only = String.replace(phone_number, ~r/\D/, "")

    cond do
      # Empty is allowed (will be caught by the disabled button)
      phone_number == "" ->
        :ok

      # Check if it's a valid Kenyan phone number format
      String.starts_with?(digits_only, "254") && String.length(digits_only) == 12 ->
        :ok

      String.starts_with?(digits_only, "0") && String.length(digits_only) == 10 ->
        :ok

      String.length(digits_only) == 9 && Regex.match?(~r/^7|1/, digits_only) ->
        :ok

      # Invalid format
      true ->
        {:error, "Please enter a valid Kenyan phone number"}
    end
  end

  defp format_error_message(reason) when is_binary(reason), do: reason
  defp format_error_message(reason), do: "Error: #{inspect(reason)}"
end
