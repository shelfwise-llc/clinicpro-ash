defmodule Clinicpro.MPesa.STKPushBehaviour do
  @moduledoc """
  Behaviour definition for the M-Pesa STK Push module.
  This allows for easy mocking in tests.
  """

  @doc """
  Initiates an STK Push request to the M-Pesa API.

  ## Parameters

  - `phone_number` - The phone number to send the STK push to
  - `amount` - The amount to charge
  - `reference` - The reference number for the _transaction
  - `_clinic_id` - The ID of the clinic (for multi-tenant support)

  ## Returns

  - `{:ok, response}` - If the request was successful
  - `{:error, reason}` - If the request failed
  """
  @callback request(String.t(), Decimal.t() | number(), String.t(), String.t()) ::
              {:ok, map()} | {:error, String.t()}
end

defmodule Clinicpro.Invoices.PaymentProcessorBehaviour do
  @moduledoc """
  Behaviour definition for the PaymentProcessor module.
  This allows for easy mocking in tests.
  """

  alias Clinicpro.Invoices.Invoice

  @doc """
  Checks the payment status of an invoice.

  ## Parameters

  - `invoice` - The invoice to check payment status for

  ## Returns

  - `{:ok, status}` - Where status is one of `:completed`, `:pending`, or `:failed`
  - `{:error, reason}` - If status check failed
  """
  @callback check_payment_status(Invoice.t()) :: {:ok, atom()} | {:error, String.t()}

  @doc """
  Processes a payment for an invoice using M-Pesa.

  ## Parameters

  - `invoice` - The invoice to process payment for
  - `phone_number` - The phone number to send the STK push to
  - `_opts` - Additional options (reserved for future use)

  ## Returns

  - `{:ok, _transaction}` - If payment was initiated successfully
  - `{:error, reason}` - If payment initiation failed
  """
  @callback process_mpesa_payment(Invoice.t(), String.t(), keyword()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Marks an invoice as paid and updates related records.

  ## Parameters

  - `invoice` - The invoice to mark as paid
  - `transaction_id` - The M-Pesa _transaction ID
  - `_opts` - Additional options (reserved for future use)

  ## Returns

  - `{:ok, updated_invoice}` - If invoice was updated successfully
  - `{:error, changeset}` - If invoice update failed
  """
  @callback mark_invoice_as_paid(Invoice.t(), String.t(), keyword()) ::
              {:ok, Invoice.t()} | {:error, any()}

  @doc """
  Handles a completed M-Pesa payment.

  ## Parameters

  - `_transaction` - The M-Pesa _transaction that was completed
  - `_opts` - Additional options (reserved for future use)

  ## Returns

  - `{:ok, updated_invoice}` - If payment was processed successfully
  - `{:error, reason}` - If payment processing failed
  """
  @callback handle_completed_payment(map(), keyword()) :: {:ok, Invoice.t()} | {:error, any()}

  @doc """
  Handles a failed M-Pesa payment.

  ## Parameters

  - `_transaction` - The M-Pesa _transaction that failed
  - `_opts` - Additional options (reserved for future use)

  ## Returns

  - `{:ok, _transaction}` - The updated _transaction
  - `{:error, reason}` - If handling the failed payment failed
  """
  @callback handle_failed_payment(map(), keyword()) :: {:ok, map()} | {:error, any()}
end
