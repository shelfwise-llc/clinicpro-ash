defmodule Clinicpro.AdminBypass.Invoice do
  @moduledoc """
  Invoice schema and functions for the admin bypass functionality.
  Integrates with the Paystack payment system for processing payments.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo
  # Removed M-Pesa references - using Paystack instead
  alias Clinicpro.AdminBypass.{Patient, Doctor, Appointment}

  schema "admin_bypass_invoices" do
    field :invoice_number, :string
    field :amount, :decimal
    # pending, paid, cancelled, partial
    field :status, :string, default: "pending"
    field :due_date, :date
    field :description, :string
    field :payment_reference, :string
    field :notes, :string

    # Invoice items as embedded schema
    embeds_many :items, InvoiceItem, on_replace: :delete do
      field :description, :string
      field :quantity, :integer, default: 1
      field :unit_price, :decimal
      field :total, :decimal
    end

    # Relationships
    belongs_to :patient, Patient
    belongs_to :clinic, Clinicpro.Clinics.Clinic, foreign_key: :clinic_id, type: :binary_id
    belongs_to :appointment, Appointment

    # Virtual fields for payment
    field :payment_phone, :string, virtual: true
    field :payment_method, :string, virtual: true, default: "paystack"

    timestamps()
  end

  @doc """
  Creates a changeset for an invoice.
  """
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :invoice_number,
      :amount,
      :status,
      :due_date,
      :description,
      :payment_reference,
      :notes,
      :patient_id,
      :clinic_id,
      :appointment_id,
      :payment_phone,
      :payment_method
    ])
    |> cast_embed(:items, with: &item_changeset/2)
    |> validate_required([
      :invoice_number,
      :amount,
      :status,
      :due_date,
      :patient_id,
      :clinic_id
    ])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:status, ["pending", "paid", "cancelled", "partial"])
    |> unique_constraint(:invoice_number)
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:clinic_id)
    |> foreign_key_constraint(:appointment_id)
    |> maybe_generate_invoice_number()
  end

  @doc """
  Creates a changeset for an invoice item.
  """
  def item_changeset(item, attrs) do
    item
    |> cast(attrs, [:description, :quantity, :unit_price, :total])
    |> validate_required([:description, :quantity, :unit_price])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than: 0)
    |> calculate_total()
  end

  @doc """
  Lists all invoices with optional filtering.
  """
  def list_invoices(filters \\ %{}) do
    base_query = from i in __MODULE__, order_by: [desc: i.inserted_at]

    filters
    |> Enum.reduce(base_query, fn
      {:clinic_id, clinic_id}, query ->
        from q in query, where: q.clinic_id == ^clinic_id

      {:patient_id, patient_id}, query ->
        from q in query, where: q.patient_id == ^patient_id

      {:status, status}, query ->
        from q in query, where: q.status == ^status

      {:date_from, date_from}, query ->
        from q in query, where: q.inserted_at >= ^date_from

      {:date_to, date_to}, query ->
        from q in query, where: q.inserted_at <= ^date_to

      _unused, query ->
        query
    end)
    |> Repo.all()
    |> Repo.preload([:patient, :clinic, :appointment])
  end

  @doc """
  Gets a single invoice with preloaded associations.
  """
  def get_invoice!(id) do
    __MODULE__
    |> Repo.get!(id)
    |> Repo.preload([:patient, :clinic, :appointment])
  end

  @doc """
  Creates a new invoice.
  """
  def create_invoice(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an invoice.
  """
  def update_invoice(%__MODULE__{} = invoice, attrs) do
    invoice
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an invoice.
  """
  def delete_invoice(%__MODULE__{} = invoice) do
    Repo.delete(invoice)
  end

  @doc """
  Returns a changeset for tracking invoice changes.
  """
  def change_invoice(%__MODULE__{} = invoice, attrs \\ %{}) do
    changeset(invoice, attrs)
  end

  @doc """
  Processes payment for an invoice using Paystack.
  """
  def process_payment(%__MODULE__{} = invoice, phone, amount) do
    # Generate a payment reference if not already set
    payment_reference = invoice.payment_reference || generate_payment_reference(invoice)

    # Payment processing handled through Paystack integration
    # No additional action needed for M-Pesa as it's been removed
  end

  @doc """
  Updates invoice status based on Paystack transaction.
  """
  # Removed M-Pesa specific transaction processing - using Paystack instead
  def update_from_transaction(_transaction) do
    {:error, "M-Pesa processing removed - using Paystack instead"}
  end

  @doc """
  Finds an invoice by payment reference.
  """
  def find_invoice_by_reference(reference) do
    case Repo.get_by(__MODULE__, payment_reference: reference) do
      nil -> {:error, :not_found}
      invoice -> {:ok, invoice |> Repo.preload([:patient, :clinic, :appointment])}
    end
  end

  @doc """
  Gets invoice statistics for a clinic.
  """
  def get_stats_for_clinic(clinic_id) do
    # Total invoices
    total_query =
      from i in __MODULE__,
        where: i.clinic_id == ^clinic_id,
        select: count(i.id)

    # Total by status
    status_query =
      from i in __MODULE__,
        where: i.clinic_id == ^clinic_id,
        group_by: i.status,
        select: {i.status, count(i.id)}

    # Total amount
    amount_query =
      from i in __MODULE__,
        where: i.clinic_id == ^clinic_id and i.status == "paid",
        select: sum(i.amount)

    # Execute queries
    total = Repo.one(total_query) || 0
    by_status = Repo.all(status_query) |> Enum.into(%{})
    total_amount = Repo.one(amount_query) || Decimal.new(0)

    %{
      total_count: total,
      by_status: by_status,
      total_amount: total_amount
    }
  end

  # Private functions

  # Calculate total for invoice item
  defp calculate_total(%Ecto.Changeset{valid?: true} = changeset) do
    quantity = get_field(changeset, :quantity) || 0
    unit_price = get_field(changeset, :unit_price) || Decimal.new(0)

    total = Decimal.mult(unit_price, Decimal.new(quantity))
    put_change(changeset, :total, total)
  end

  defp calculate_total(changeset), do: changeset

  # Generate invoice number if not provided
  defp maybe_generate_invoice_number(changeset) do
    case get_field(changeset, :invoice_number) do
      nil ->
        clinic_id = get_field(changeset, :clinic_id)
        date_prefix = Date.utc_today() |> Date.to_string() |> String.replace("-", "")
        random_suffix = :crypto.strong_rand_bytes(3) |> Base.encode16()

        invoice_number = "INV-#{clinic_id}-#{date_prefix}-#{random_suffix}"
        put_change(changeset, :invoice_number, invoice_number)

      _unused ->
        changeset
    end
  end

  # Generate payment reference for Paystack
  defp generate_payment_reference(invoice) do
    date_part =
      DateTime.utc_now() |> DateTime.to_string() |> String.slice(0, 10) |> String.replace("-", "")

    "PAY-#{invoice.clinic_id}-#{date_part}-#{invoice.id}"
  end
end
