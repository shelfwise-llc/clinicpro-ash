defmodule Clinicpro.MPesa.STKPushBehaviour do
  @moduledoc """
  Defines the behaviour for M-Pesa STK Push implementations.
  This allows for different implementations (e.g., live, mock) to be used
  interchangeably, facilitating testing and development.
  """

  @doc """
  Sends an STK Push request to the M-Pesa API.

  ## Parameters

  - `phone_number` - The phone number to send the STK Push to
  - `amount` - The amount to charge
  - `reference` - The reference for the _transaction (usually invoice number)
  - `description` - Description of the _transaction
  - `_clinic_id` - The ID of the clinic initiating the payment

  ## Returns

  - `{:ok, response}` - If the request was successful
  - `{:error, reason}` - If the request failed
  """
  @callback send_stk_push(
    phone_number :: String.t(),
    amount :: number(),
    reference :: String.t(),
    description :: String.t(),
    _clinic_id :: integer()
  ) :: {:ok, map()} | {:error, any()}

  @doc """
  Queries the status of an STK Push request.

  ## Parameters

  - `checkout_request_id` - The checkout request ID to check
  - `merchant_request_id` - The merchant request ID
  - `_clinic_id` - The ID of the clinic that initiated the payment

  ## Returns

  - `{:ok, response}` - If the request was successful
  - `{:error, reason}` - If the request failed
  """
  @callback query_stk_push_status(
    checkout_request_id :: String.t(),
    merchant_request_id :: String.t(),
    _clinic_id :: integer()
  ) :: {:ok, map()} | {:error, any()}
end
