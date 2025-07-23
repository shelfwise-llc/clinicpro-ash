defmodule Clinicpro.MPesa.InvoiceIntegration do
  @moduledoc """
  Integration between M-Pesa and the Invoice system.

  This module provides functions to connect M-Pesa transactions with invoices,
  update invoice statuses based on payment status, and trigger STK Push payments
  from the invoice UI.
  """

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Invoices

  @doc """
  Updates an invoice status based on a successful M-Pesa transaction.

  ## Parameters

  * `transaction` - The M-Pesa transaction

  ## Returns

  * `{:ok, invoice}` - If the invoice was updated successfully
  * `{:error, reason}` - If the invoice update failed
  """
  def update_invoice_status(%Transaction{} = transaction) do
    with {:ok, invoice} <- Invoices.get_invoice(transaction.invoice_id, transaction.clinic_id),
         {:ok, updated_invoice} <- do_update_invoice_status(invoice, transaction) do
      {:ok, updated_invoice}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Initiates an STK Push payment for an invoice.

  ## Parameters

  * `invoice_id` - The ID of the invoice to pay
  * `clinic_id` - The ID of the clinic
  * `phone_number` - The phone number to send the STK Push to
  * `amount` - The amount to pay (optional, defaults to invoice amount)

  ## Returns

  * `{:ok, transaction}` - If the STK Push was initiated successfully
  * `{:error, reason}` - If the STK Push initiation failed
  """
  def initiate_stk_push_for_invoice(invoice_id, clinic_id, phone_number, amount \\ nil) do
    with {:ok, invoice} <- Invoices.get_invoice(invoice_id, clinic_id),
         amount = amount || invoice.amount,
         patient_id = invoice.patient_id,
         {:ok, transaction} <- MPesa.initiate_stk_push(clinic_id, invoice_id, patient_id, phone_number, amount) do
      {:ok, transaction}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets all transactions for an invoice.

  ## Parameters

  * `invoice_id` - The ID of the invoice
  * `clinic_id` - The ID of the clinic

  ## Returns

  * List of transactions
  """
  def get_invoice_transactions(invoice_id, clinic_id) do
    Transaction.list_by_invoice(invoice_id, clinic_id)
  end

  @doc """
  Gets the payment status of an invoice based on its transactions.

  ## Parameters

  * `invoice_id` - The ID of the invoice
  * `clinic_id` - The ID of the clinic

  ## Returns

  * `:paid` - If the invoice is fully paid
  * `:partially_paid` - If the invoice is partially paid
  * `:pending` - If there are pending transactions
  * `:unpaid` - If there are no transactions or all have failed
  """
  def get_invoice_payment_status(invoice_id, clinic_id) do
    with {:ok, invoice} <- Invoices.get_invoice(invoice_id, clinic_id) do
      transactions = get_invoice_transactions(invoice_id, clinic_id)

      cond do
        Enum.any?(transactions, &(&1.status == "pending")) ->
          :pending

        total_paid_amount(transactions) >= invoice.amount ->
          :paid

        total_paid_amount(transactions) > 0 ->
          :partially_paid

        true ->
          :unpaid
      end
    else
      {:error, _} -> :error
    end
  end

  # Private functions

  defp do_update_invoice_status(invoice, %{status: "completed"} = transaction) do
    # Calculate the total amount paid for this invoice
    total_paid = total_paid_amount(get_invoice_transactions(invoice.id, invoice.clinic_id))

    # Determine the new status based on the amount paid
    new_status = if total_paid >= invoice.amount, do: "paid", else: "partially_paid"

    # Update the invoice status
    Invoices.update_invoice(invoice, %{
      payment_status: new_status,
      last_payment_date: transaction.updated_at,
      amount_paid: total_paid
    })
  end

  defp do_update_invoice_status(invoice, %{status: "failed"}) do
    # Don't change the invoice status for failed transactions
    {:ok, invoice}
  end

  defp do_update_invoice_status(invoice, %{status: "pending"}) do
    # Update to pending only if the invoice is not already paid or partially paid
    if invoice.payment_status not in ["paid", "partially_paid"] do
      Invoices.update_invoice(invoice, %{payment_status: "pending"})
    else
      {:ok, invoice}
    end
  end

  defp total_paid_amount(transactions) do
    transactions
    |> Enum.filter(&(&1.status == "completed"))
    |> Enum.reduce(0, fn tx, acc -> acc + tx.amount end)
  end
end
