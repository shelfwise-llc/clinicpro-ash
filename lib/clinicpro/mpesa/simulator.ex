defmodule Clinicpro.MPesaCallbackSimulator do
  @moduledoc """
  Simulation script for testing M-Pesa callbacks with virtual meeting integration.

  This module provides functions to simulate M-Pesa callbacks for testing purposes.
  It can be used to verify that the payment processing and virtual meeting creation
  work correctly without having to make actual M-Pesa API calls.
  """

  alias HTTPoison
  alias Jason

  @doc """
  Simulates an STK Push callback for a completed payment.

  ## Parameters

  * `reference` - The payment reference (invoice reference)
  * `_clinic_id` - The ID of the clinic
  * `amount` - The payment amount
  * `phone` - The phone number that made the payment

  ## Returns

  * `{:ok, response}` - On success, returns the HTTP response
  * `{:error, reason}` - On failure, returns an error reason
  """
  def simulate_stk_callback(reference, _clinic_id, amount, phone) do
    callback_url = "http://localhost:4000/api/mpesa/callbacks/stk/#{_clinic_id}"

    # Create a realistic STK callback payload
    payload = %{
      "Body" => %{
        "stkCallback" => %{
          "MerchantRequestID" => "#{_clinic_id}-#{:os.system_time(:millisecond)}",
          "CheckoutRequestID" => "ws_CO_#{:os.system_time(:millisecond)}",
          "ResultCode" => 0,
          "ResultDesc" => "The service request is processed successfully.",
          "CallbackMetadata" => %{
            "Item" => [
              %{
                "Name" => "Amount",
                "Value" => amount
              },
              %{
                "Name" => "MpesaReceiptNumber",
                "Value" => "#{random_receipt_number()}"
              },
              %{
                "Name" => "TransactionDate",
                "Value" => format_transaction_date()
              },
              %{
                "Name" => "PhoneNumber",
                "Value" => phone
              }
            ]
          }
        }
      }
    }

    # Add the reference to the payload (normally this would be in the callback metadata)
    # In a real implementation, this would be part of the original STK push request
    payload = put_in(payload, ["Body", "stkCallback", "reference"], reference)

    # Send the callback to the local server
    HTTPoison.post(callback_url, Jason.encode!(payload), [{"Content-Type", "application/json"}])
  end

  @doc """
  Simulates a C2B callback for a completed payment.

  ## Parameters

  * `reference` - The payment reference (invoice reference)
  * `_clinic_id` - The ID of the clinic
  * `amount` - The payment amount
  * `phone` - The phone number that made the payment

  ## Returns

  * `{:ok, response}` - On success, returns the HTTP response
  * `{:error, reason}` - On failure, returns an error reason
  """
  def simulate_c2b_callback(reference, _clinic_id, amount, phone) do
    callback_url = "http://localhost:4000/api/mpesa/callbacks/c2b/#{_clinic_id}"

    # Create a realistic C2B callback payload
    payload = %{
      "TransactionType" => "Pay Bill",
      "TransID" => "#{random_receipt_number()}",
      "TransTime" => format_transaction_date(),
      "TransAmount" => "#{amount}",
      "BusinessShortCode" => "123456",
      "BillRefNumber" => reference,
      "InvoiceNumber" => "",
      "OrgAccountBalance" => "",
      "ThirdPartyTransID" => "",
      "MSISDN" => phone,
      "FirstName" => "John",
      "MiddleName" => "",
      "LastName" => "Doe"
    }

    # Send the callback to the local server
    HTTPoison.post(callback_url, Jason.encode!(payload), [{"Content-Type", "application/json"}])
  end

  # Helper functions

  defp random_receipt_number do
    # Generate a random M-Pesa receipt number (format: LHG12AB3CD)
    letters = for _ <- 1..3, into: "", do: <<Enum.random(?A..?Z)>>
    numbers = for _ <- 1..2, into: "", do: <<Enum.random(?0..?9)>>
    letters2 = for _ <- 1..2, into: "", do: <<Enum.random(?A..?Z)>>
    numbers2 = for _ <- 1..2, into: "", do: <<Enum.random(?0..?9)>>

    "#{letters}#{numbers}#{letters2}#{numbers2}"
  end

  defp format_transaction_date do
    # Format current datetime as YYYYMMDDHHmmss
    DateTime.utc_now()
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end
end

# Example usage:
#
# # Simulate STK Push callback
# Clinicpro.MPesaCallbackSimulator.simulate_stk_callback(
#   "INV-123456",  # invoice reference
#   1,             # _clinic_id
#   1000.0,        # amount
#   "254712345678" # phone
# )
#
# # Simulate C2B callback
# Clinicpro.MPesaCallbackSimulator.simulate_c2b_callback(
#   "INV-123456",  # invoice reference
#   1,             # _clinic_id
#   1000.0,        # amount
#   "254712345678" # phone
# )
