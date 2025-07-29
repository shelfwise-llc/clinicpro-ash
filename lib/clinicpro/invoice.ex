defmodule Clinicpro.Invoice do
  @moduledoc """
  Facade module for invoice operations.

  This module provides a simplified interface to the Clinicpro.AdminBypass.Invoice
  functionality, making it easier to work with invoices across the application.
  It serves as a compatibility layer for code that expects a singular Invoice module.
  """

  alias Clinicpro.AdminBypass.Invoice, as: InvoiceSchema
  alias Clinicpro.Repo

  @doc """
  Gets an invoice by ID and clinic ID.

  ## Parameters

  * `id` - Invoice ID
  * `clinic_id` - Clinic ID

  ## Returns

  * `{:ok, invoice}` - The invoice if found
  * `{:error, :not_found}` - If no invoice found
  """
  def get_by_id(id, clinic_id) do
    case Repo.get_by(InvoiceSchema, id: id, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      invoice -> {:ok, Repo.preload(invoice, [:patient, :clinic, :appointment])}
    end
  end

  @doc """
  Gets an invoice by ID.

  ## Parameters

  * `id` - Invoice ID

  ## Returns

  * The invoice if found
  * nil if not found
  """
  def get(id) do
    InvoiceSchema
    |> Repo.get(id)
    |> Repo.preload([:patient, :clinic, :appointment])
  end

  @doc """
  Lists all invoices for a clinic.

  ## Parameters

  * `clinic_id` - Clinic ID
  * `filters` - Optional filters to apply

  ## Returns

  * List of invoices
  """
  def list_by_clinic(clinic_id, filters \\ %{}) do
    InvoiceSchema.list_invoices(Map.put(filters, :clinic_id, clinic_id))
  end

  @doc """
  Creates a new invoice.

  ## Parameters

  * `attrs` - Invoice attributes

  ## Returns

  * `{:ok, invoice}` - The created invoice
  * `{:error, changeset}` - If validation fails
  """
  def create(attrs) do
    InvoiceSchema.create_invoice(attrs)
  end

  @doc """
  Updates an invoice.

  ## Parameters

  * `invoice` - The invoice to update
  * `attrs` - Attributes to update

  ## Returns

  * `{:ok, invoice}` - The updated invoice
  * `{:error, changeset}` - If validation fails
  """
  def update(invoice, attrs) do
    InvoiceSchema.update_invoice(invoice, attrs)
  end

  @doc """
  Deletes an invoice.

  ## Parameters

  * `invoice` - The invoice to delete

  ## Returns

  * `{:ok, invoice}` - The deleted invoice
  * `{:error, changeset}` - If deletion fails
  """
  def delete(invoice) do
    InvoiceSchema.delete_invoice(invoice)
  end

  @doc """
  Processes payment for an invoice.

  ## Parameters

  * `invoice` - The invoice to process payment for
  * `phone` - Phone number for payment
  * `amount` - Amount to pay

  ## Returns

  * `{:ok, response}` - Payment initiated successfully
  * `{:error, reason}` - If payment initiation fails
  """
  def process_payment(invoice, phone, amount) do
    InvoiceSchema.process_payment(invoice, phone, amount)
  end

  @doc """
  Finds an invoice by payment reference.

  ## Parameters

  * `reference` - Payment reference

  ## Returns

  * `{:ok, invoice}` - The invoice if found
  * `{:error, :not_found}` - If no invoice found
  """
  def find_by_reference(reference) do
    InvoiceSchema.find_invoice_by_reference(reference)
  end
end
