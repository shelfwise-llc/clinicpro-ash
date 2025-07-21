defmodule Clinicpro.MPesa.Transaction do
  @moduledoc """
  Tracks M-Pesa transactions for all clinics.

  This module is responsible for:
  1. Creating and updating transaction records
  2. Querying transactions by various attributes
  3. Managing transaction lifecycle
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Clinicpro.Repo
  alias Clinicpro.AdminBypass.Doctor

  schema "mpesa_transactions" do
    field :checkout_request_id, :string
    field :merchant_request_id, :string
    field :reference, :string
    field :phone, :string
    field :amount, :decimal
    field :description, :string
    field :status, :string, default: "pending"
    field :result_code, :string
    field :result_desc, :string
    field :transaction_date, :utc_datetime
    field :mpesa_receipt_number, :string
    # "stk_push" or "c2b"
    field :type, :string
    field :raw_request, :map
    field :raw_response, :map

    belongs_to :clinic, Doctor, foreign_key: :clinic_id

    timestamps()
  end

  @doc """
  Creates a pending transaction.

  ## Parameters

  - attrs: Transaction attributes

  ## Returns

  - {:ok, transaction} on success
  - {:error, changeset} on validation failure
  """
  def create_pending(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:clinic_id, :phone, :amount, :reference, :description, :type])
    |> validate_required([:clinic_id, :phone, :amount, :reference, :type])
    |> validate_inclusion(:type, ["stk_push", "c2b"])
    |> validate_number(:amount, greater_than: 0)
    |> put_change(:status, "pending")
    |> Repo.insert()
  end

  @doc """
  Updates a transaction with new attributes.

  ## Parameters

  - transaction: The transaction to update
  - attrs: New attributes

  ## Returns

  - {:ok, transaction} on success
  - {:error, changeset} on validation failure
  """
  def update(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :checkout_request_id,
      :merchant_request_id,
      :status,
      :result_code,
      :result_desc,
      :transaction_date,
      :mpesa_receipt_number,
      :raw_request,
      :raw_response
    ])
    |> Repo.update()
  end

  @doc """
  Finds a transaction by its checkout request ID.

  ## Parameters

  - checkout_request_id: The checkout request ID to search for

  ## Returns

  - {:ok, transaction} if found
  - {:error, :not_found} if not found
  """
  def find_by_checkout_request_id(checkout_request_id) do
    case Repo.get_by(__MODULE__, checkout_request_id: checkout_request_id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  @doc """
  Finds a transaction by its M-Pesa receipt number.

  ## Parameters

  - receipt_number: The M-Pesa receipt number to search for

  ## Returns

  - {:ok, transaction} if found
  - {:error, :not_found} if not found
  """
  def find_by_receipt_number(receipt_number) do
    case Repo.get_by(__MODULE__, mpesa_receipt_number: receipt_number) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  @doc """
  Finds a transaction by its reference.

  ## Parameters

  - reference: The transaction reference to search for

  ## Returns

  - transaction if found
  - nil if not found
  """
  def find_by_reference(reference) do
    Repo.get_by(__MODULE__, reference: reference)
  end

  @doc """
  Lists transactions for a specific clinic with pagination.

  ## Parameters

  - clinic_id: The ID of the clinic to list transactions for
  - page: Page number (default: 1)
  - per_page: Number of transactions per page (default: 20)
  - filters: Map of filters to apply (e.g., %{status: "completed", type: "stk_push"})

  ## Returns

  - List of transactions
  """
  def list_for_clinic(clinic_id, page \\ 1, per_page \\ 20, filters \\ %{}) do
    base_query =
      from(t in __MODULE__,
        where: t.clinic_id == ^clinic_id
      )

    # Apply filters
    filtered_query = apply_filters(base_query, filters)

    # Apply pagination and ordering
    from(t in filtered_query,
      order_by: [desc: t.inserted_at],
      limit: ^per_page,
      offset: ^((page - 1) * per_page)
    )
    |> Repo.all()
  end

  @doc """
  Counts transactions for a specific clinic.

  ## Parameters

  - clinic_id: The ID of the clinic to count transactions for
  - filters: Map of filters to apply (e.g., %{status: "completed", type: "stk_push"})

  ## Returns

  - Count of transactions
  """
  def count_for_clinic(clinic_id, filters \\ %{}) do
    base_query =
      from(t in __MODULE__,
        where: t.clinic_id == ^clinic_id
      )

    # Apply filters
    filtered_query = apply_filters(base_query, filters)

    from(t in filtered_query,
      select: count(t.id)
    )
    |> Repo.one()
  end

  @doc """
  Lists recent transactions for a specific clinic.

  ## Parameters

  - clinic_id: The ID of the clinic to list transactions for
  - limit: Maximum number of transactions to return (default: 10)

  ## Returns

  - List of recent transactions
  """
  def list_recent_for_clinic(clinic_id, limit \\ 10) do
    from(t in __MODULE__,
      where: t.clinic_id == ^clinic_id,
      order_by: [desc: t.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Lists transactions by status for a specific clinic.

  ## Parameters

  - clinic_id: The ID of the clinic to list transactions for
  - status: Status to filter by (e.g., "pending", "completed", "failed")
  - page: Page number (default: 1)
  - per_page: Number of transactions per page (default: 20)

  ## Returns

  - List of transactions with the specified status
  """
  def list_by_status(clinic_id, status, page \\ 1, per_page \\ 20) do
    from(t in __MODULE__,
      where: t.clinic_id == ^clinic_id and t.status == ^status,
      order_by: [desc: t.inserted_at],
      limit: ^per_page,
      offset: ^((page - 1) * per_page)
    )
    |> Repo.all()
  end

  @doc """
  Gets transaction statistics for a specific clinic.

  ## Parameters

  - clinic_id: The ID of the clinic to get statistics for

  ## Returns

  - Map with transaction statistics
  """
  def get_statistics(clinic_id) do
    # Get total count
    total_query =
      from(t in __MODULE__,
        where: t.clinic_id == ^clinic_id,
        select: count(t.id)
      )

    # Get count by status
    status_query =
      from(t in __MODULE__,
        where: t.clinic_id == ^clinic_id,
        group_by: t.status,
        select: {t.status, count(t.id)}
      )

    # Get sum of completed transactions
    sum_query =
      from(t in __MODULE__,
        where: t.clinic_id == ^clinic_id and t.status == "completed",
        select: sum(t.amount)
      )

    # Execute queries
    total = Repo.one(total_query) || 0
    status_counts = Repo.all(status_query) |> Enum.into(%{})
    total_amount = Repo.one(sum_query) || Decimal.new(0)

    # Return statistics
    %{
      total: total,
      by_status: status_counts,
      total_amount: total_amount
    }
  end

  @doc """
  Gets comprehensive transaction statistics for a specific clinic.
  This is used for the admin dashboard.

  ## Parameters

  - clinic_id: The ID of the clinic to get statistics for

  ## Returns

  - Map with detailed transaction statistics
  """
  def get_stats_for_clinic(clinic_id) do
    # Get total count
    total_count = count_for_clinic(clinic_id)

    # Get counts by status
    completed_count = count_for_clinic(clinic_id, %{status: "completed"})
    pending_count = count_for_clinic(clinic_id, %{status: "pending"})
    failed_count = count_for_clinic(clinic_id, %{status: "failed"})

    # Get total amount of completed transactions
    total_amount_query =
      from(t in __MODULE__,
        where: t.clinic_id == ^clinic_id and t.status == "completed",
        select: sum(t.amount)
      )

    total_amount = Repo.one(total_amount_query) || Decimal.new(0)

    # Return comprehensive statistics
    %{
      total_count: total_count,
      completed_count: completed_count,
      pending_count: pending_count,
      failed_count: failed_count,
      total_amount: total_amount
    }
  end

  # Private functions

  @doc false
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from(t in query, where: t.status == ^status)

      {:type, type}, query ->
        from(t in query, where: t.type == ^type)

      {:date_from, date_from}, query ->
        from(t in query, where: t.inserted_at >= ^date_from)

      {:date_to, date_to}, query ->
        from(t in query, where: t.inserted_at <= ^date_to)

      {:reference, reference}, query ->
        from(t in query, where: ilike(t.reference, ^"%#{reference}%"))

      {:phone, phone}, query ->
        from(t in query, where: ilike(t.phone, ^"%#{phone}%"))

      _, query ->
        query
    end)
  end
end
