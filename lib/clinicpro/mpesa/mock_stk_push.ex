defmodule Clinicpro.MPesa.MockSTKPush do
  @moduledoc """
  Mock implementation of the M-Pesa STK Push for testing purposes.
  This module implements the STKPushBehaviour interface but returns
  predictable responses instead of making actual API calls.
  """

  require Logger
  alias Clinicpro.MPesa.Config

  @behaviour Clinicpro.MPesa.STKPushBehaviour

  @doc """
  Mock implementation of send_stk_push that returns a successful response
  without making an actual API call.

  ## Parameters

  - `phone_number` - The phone number to send the STK Push to
  - `amount` - The amount to charge
  - `reference` - The reference for the transaction (usually invoice number)
  - `description` - Description of the transaction
  - `clinic_id` - The ID of the clinic initiating the payment

  ## Returns

  - `{:ok, response}` - A mock successful response
  """
  @impl Clinicpro.MPesa.STKPushBehaviour
  def send_stk_push(phone_number, amount, _reference, _description, clinic_id) do
    # Log the mock request
    Logger.info("MOCK: Sending STK Push for clinic #{clinic_id} to #{phone_number} for amount #{amount}")

    # Get the clinic's config to ensure it exists
    _config = Config.get_config(clinic_id)

    # Generate mock IDs
    checkout_request_id = "ws_co_#{:rand.uniform(999999999)}"
    merchant_request_id = "ws_mc_#{:rand.uniform(999999999)}"

    # Return a successful mock response
    {:ok, %{
      checkout_request_id: checkout_request_id,
      merchant_request_id: merchant_request_id
    }}
  end

  @doc """
  Mock implementation of query_stk_push_status that returns a successful response
  without making an actual API call.

  ## Parameters

  - `checkout_request_id` - The checkout request ID to check
  - `merchant_request_id` - The merchant request ID
  - `clinic_id` - The ID of the clinic that initiated the payment

  ## Returns

  - `{:ok, response}` - A mock successful response
  """
  @impl Clinicpro.MPesa.STKPushBehaviour
  def query_stk_push_status(checkout_request_id, _merchant_request_id, clinic_id) do
    # Log the mock request
    Logger.info("MOCK: Querying STK Push status for clinic #{clinic_id}, checkout request ID: #{checkout_request_id}")

    # Get the clinic's config to ensure it exists
    _config = Config.get_config(clinic_id)

    # Return a successful mock response
    {:ok, %{
      result_code: "0",
      result_desc: "The service request is processed successfully."
    }}
  end

  @doc """
  Simulates an STK Push callback for testing purposes.

  ## Parameters

  - `checkout_request_id` - The checkout request ID to simulate a callback for
  - `merchant_request_id` - The merchant request ID
  - `phone_number` - The phone number that made the payment
  - `amount` - The amount paid
  - `transaction_id` - Optional transaction ID (generated if not provided)
  - `success` - Whether the transaction was successful

  ## Returns

  - `{:ok, callback_data}` - The simulated callback data
  """
  def simulate_callback(checkout_request_id, merchant_request_id, phone_number, amount, transaction_id \\ nil, success \\ true) do
    # Generate a transaction ID if not provided
    transaction_id = transaction_id || "WS#{:rand.uniform(999999999)}"

    # Generate a timestamp
    timestamp = DateTime.utc_now()
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.replace(~r/[^\d]/, "")
    |> String.slice(0, 14)

    # Build the callback data
    result_code = if success, do: "0", else: "1"
    result_desc = if success, do: "The service request is processed successfully.", else: "Failed"

    callback_data = %{
      "Body" => %{
        "stkCallback" => %{
          "MerchantRequestID" => merchant_request_id,
          "CheckoutRequestID" => checkout_request_id,
          "ResultCode" => result_code,
          "ResultDesc" => result_desc,
          "CallbackMetadata" => %{
            "Item" => [
              %{"Name" => "Amount", "Value" => amount},
              %{"Name" => "MpesaReceiptNumber", "Value" => transaction_id},
              %{"Name" => "TransactionDate", "Value" => timestamp},
              %{"Name" => "PhoneNumber", "Value" => phone_number}
            ]
          }
        }
      }
    }

    {:ok, callback_data}
  end

  @doc """
  Simulates a C2B callback for testing purposes.

  ## Parameters

  - `shortcode` - The business shortcode
  - `phone_number` - The phone number that made the payment
  - `amount` - The amount paid
  - `reference` - The bill reference number
  - `transaction_id` - Optional transaction ID (generated if not provided)

  ## Returns

  - `{:ok, callback_data}` - The simulated callback data
  """
  def simulate_c2b_callback(shortcode, phone_number, amount, reference, transaction_id \\ nil) do
    # Generate a transaction ID if not provided
    transaction_id = transaction_id || "WS#{:rand.uniform(999999999)}"

    # Generate a timestamp in the format YYYYMMDDHHmmss
    timestamp = DateTime.utc_now()
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.replace(~r/[^\d]/, "")
    |> String.slice(0, 14)

    # Build the callback data
    callback_data = %{
      "TransactionType" => "Pay Bill",
      "TransID" => transaction_id,
      "TransTime" => timestamp,
      "TransAmount" => amount,
      "BusinessShortCode" => shortcode,
      "BillRefNumber" => reference,
      "InvoiceNumber" => "",
      "OrgAccountBalance" => "",
      "ThirdPartyTransID" => "",
      "MSISDN" => phone_number,
      "FirstName" => "John",
      "MiddleName" => "",
      "LastName" => "Doe"
    }

    {:ok, callback_data}
  end
end
