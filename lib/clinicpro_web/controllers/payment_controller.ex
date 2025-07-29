defmodule ClinicproWeb.PaymentController do
  use ClinicproWeb, :controller

  alias Clinicpro.Invoices
  alias Clinicpro.Appointments

  @doc """
  Show payment details for an invoice.
  """
  def show(conn, %{"invoice_id" => invoice_id}) do
    case Invoices.get_invoice(invoice_id) do
      nil ->
        conn
        |> put_flash(:error, "Invoice not found.")
        |> redirect(to: ~p"/patient/dashboard")

      invoice ->
        render(conn, :show, invoice: invoice)
    end
  end

  # M-Pesa functions removed - using Paystack instead

  # Helper functions

  defp format_phone_number(phone) do
    # Remove any non-digit characters
    digits = String.replace(phone, ~r/\D/, "")

    # Ensure the number starts with 254 (Kenya country code)
    cond do
      String.starts_with?(digits, "254") -> digits
      String.starts_with?(digits, "0") -> "254" <> String.slice(digits, 1..-1)
      String.starts_with?(digits, "+254") -> String.slice(digits, 1..-1)
      true -> "254" <> digits
    end
  end

  defp get_appointment_type(invoice_id) do
    # Get the appointment associated with this invoice
    case Appointments.get_appointment_by_invoice(invoice_id) do
      nil -> "unknown"
      # Default to onsite if not specified
      appointment -> appointment.appointment_type || "onsite"
    end
  end
end
