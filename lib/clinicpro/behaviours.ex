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
  Marks an invoice as paid and updates related records.

  ## Parameters

  - `invoice` - The invoice to mark as paid
  - `transaction_id` - The Paystack transaction ID
  - `_opts` - Additional options (reserved for future use)

  ## Returns

  - `{:ok, updated_invoice}` - If invoice was updated successfully
  - `{:error, changeset}` - If invoice update failed
  """
  @callback mark_invoice_as_paid(Invoice.t(), String.t(), keyword()) ::
              {:ok, Invoice.t()} | {:error, any()}

  @doc """
  Handles a completed Paystack payment.

  ## Parameters

  - `_transaction` - The Paystack transaction that was completed
  - `_opts` - Additional options (reserved for future use)

  ## Returns

  - `{:ok, updated_invoice}` - If payment was processed successfully
  - `{:error, reason}` - If payment processing failed
  """
  @callback handle_completed_payment(map(), keyword()) :: {:ok, Invoice.t()} | {:error, any()}

  @doc """
  Handles a failed Paystack payment.

  ## Parameters

  - `_transaction` - The Paystack transaction that failed
  - `_opts` - Additional options (reserved for future use)

  ## Returns

  - `{:ok, _transaction}` - The updated _transaction
  - `{:error, reason}` - If handling the failed payment failed
  """
  @callback handle_failed_payment(map(), keyword()) :: {:ok, map()} | {:error, any()}
end
