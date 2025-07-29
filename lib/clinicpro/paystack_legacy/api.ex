defmodule Clinicpro.PaystackLegacy.API do
  @moduledoc """
  Legacy API module for Paystack integration.

  This module provides legacy Paystack API functions for backward compatibility.
  It delegates to the new Paystack API implementation.
  """

  require Logger
  alias Clinicpro.Paystack.API, as: NewAPI

  @doc """
  Initializes a transaction on Paystack.
  Delegates to the new API implementation.
  """
  def initialize_transaction(
        email,
        amount,
        reference,
        callback_url,
        metadata,
        subaccount \\ nil,
        clinic_id
      ) do
    NewAPI.initialize_transaction(
      email,
      amount,
      reference,
      callback_url,
      metadata,
      subaccount,
      clinic_id
    )
  end

  @doc """
  Verifies a transaction on Paystack.
  Delegates to the new API implementation.
  """
  def verify_transaction(reference, clinic_id) do
    NewAPI.verify_transaction(reference, clinic_id)
  end

  @doc """
  Gets a transaction with events from Paystack.
  Delegates to the new API implementation.
  """
  def get_transaction_with_events(reference, clinic_id) do
    # Delegate to the new API implementation if it exists
    # Otherwise return a mock response
    case function_exported?(NewAPI, :get_transaction_with_events, 2) do
      true ->
        NewAPI.get_transaction_with_events(reference, clinic_id)

      false ->
        Logger.warning(
          "NewAPI.get_transaction_with_events/2 not implemented, returning mock data"
        )

        {:ok, %{"data" => %{"events" => []}}}
    end
  end
end
