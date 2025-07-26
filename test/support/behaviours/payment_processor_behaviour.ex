defmodule Clinicpro.Invoices.PaymentProcessorBehaviour do
  @moduledoc """
  Behaviour definition for mocking Payment Processor functionality in tests.
  """

  @callback initiate_payment(map(), binary(), map()) :: {:ok, map()} | {:error, any()}
  @callback check_payment_status(map()) :: {:ok, map()} | {:error, any()}
  @callback process_successful_payment(map(), map(), map()) :: {:ok, map()} | {:error, any()}
  @callback process_failed_payment(map(), binary()) :: {:ok, map()} | {:error, any()}
end
