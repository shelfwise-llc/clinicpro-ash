defmodule Clinicpro.MPesa.Transaction do
  @moduledoc """
  Module for handling M-Pesa transactions with multi-tenant support.

  This module provides functions for creating, updating, and querying M-Pesa transactions,
  ensuring proper isolation between clinics in a multi-tenant environment.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  # # alias Clinicpro.Repo
  alias __MODULE__

  schema "mpesa_transactions" do
    field :_clinic_id, :integer
    field :invoice_id, :string
    field :patient_id, :string
    field :phone_number, :string
    field :amount, :float
    field :status, :string, default: "pending"
    field :reference, :string
    field :checkout_request_id, :string
    field :merchant_request_id, :string
    field :transaction_id, :string
    field :transaction_date, :naive_datetime
    field :result_code, :string
    field :result_desc, :string

    timestamps()
  end

  @doc """
  Creates a new M-Pesa _transaction.

  ## Parameters

  * `attrs` - Map of attributes for the _transaction

  ## Returns

  * `{:ok, _transaction}` - On success
  * `{:error, changeset}` - On failure
  """
  def create(attrs) do
    %Transaction{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing M-Pesa _transaction.

  ## Parameters

  * `_transaction` - The _transaction to update
  * `attrs` - Map of attributes to update

  ## Returns

  * `{:ok, _transaction}` - On success
  * `{:error, changeset}` - On failure
  """
  def update(_transaction, attrs) do
    _transaction
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a _transaction with request IDs.

  ## Parameters

  * `id` - The ID of the _transaction to update
  * `checkout_request_id` - The checkout request ID from M-Pesa
  * `merchant_request_id` - The merchant request ID from M-Pesa

  ## Returns

  * `{:ok, _transaction}` - On success
  * `{:error, changeset}` - On failure
  """
  def update_request_ids(id, checkout_request_id, merchant_request_id) do
    _transaction = get_by_id(id)
    
    if _transaction do
      _transaction
      |> Ecto.Changeset.change(%{
        checkout_request_id: checkout_request_id,
        merchant_request_id: merchant_request_id
      })
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Updates a _transaction's status.

  ## Parameters

  * `id` - The ID of the _transaction to update
  * `status` - The new status ("pending", "completed", "failed")
  * `result_code` - The result code from M-Pesa
  * `result_desc` - The result description from M-Pesa
  * `transaction_id` - (Optional) The _transaction ID from M-Pesa
  * `transaction_date` - (Optional) The _transaction date from M-Pesa

  ## Returns

  * `{:ok, _transaction}` - On success
  * `{:error, changeset}` - On failure
  """
  def update_status(id, status, result_code, result_desc, transaction_id \\ nil, transaction_date \\ nil) do
    attrs = %{
      status: status,
      result_code: result_code,
      result_desc: result_desc
    }

    # Add transaction_id if provided
    attrs = if transaction_id, do: Map.put(attrs, :transaction_id, transaction_id), else: attrs

    # Add transaction_date if provided
    attrs = if transaction_date, do: Map.put(attrs, :transaction_date, transaction_date), else: attrs

    _transaction = get_by_id(id)
    
    if _transaction do
      _transaction
      |> Ecto.Changeset.change(attrs)
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Gets a _transaction by ID.

  ## Parameters

  * `id` - The ID of the _transaction to get

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_id(id) do
    Repo.get(Transaction, id)
  end

  @doc """
  Gets a _transaction by checkout request ID.

  ## Parameters

  * `checkout_request_id` - The checkout request ID to search for
  * `_clinic_id` - Optional clinic ID to ensure proper isolation

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_checkout_request_id(checkout_request_id, _clinic_id \\ nil) do
    query = from t in Transaction, where: t.checkout_request_id == ^checkout_request_id
    query = if _clinic_id, do: where(query, [t], t._clinic_id == ^_clinic_id), else: query
    Repo.one(query)
  end

  @doc """
  Gets a _transaction by merchant request ID.

  ## Parameters

  * `merchant_request_id` - The merchant request ID to search for
  * `_clinic_id` - Optional clinic ID to ensure proper isolation

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_merchant_request_id(merchant_request_id, _clinic_id \\ nil) do
    query = from t in Transaction, where: t.merchant_request_id == ^merchant_request_id
    query = if _clinic_id, do: where(query, [t], t._clinic_id == ^_clinic_id), else: query
    Repo.one(query)
  end

  @doc """
  Gets a _transaction by reference and clinic ID.

  ## Parameters

  * `reference` - The reference to search for
  * `_clinic_id` - The clinic ID to search for

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_reference_and_clinic(reference, _clinic_id) do
    Repo.get_by(Transaction, reference: reference, _clinic_id: _clinic_id)
  end

  @doc """
  Lists all transactions for a specific clinic with optional limit.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to list transactions for
  * `_opts` - Options map with optional :limit key

  ## Returns

  * List of transactions
  """
  def list_by_clinic(_clinic_id, _opts \\ %{}) do
    limit = Map.get(_opts, :limit)
    
    query = Transaction
    |> where(_clinic_id: ^_clinic_id)
    |> order_by(desc: :inserted_at)
    
    query = if limit, do: limit(query, ^limit), else: query
    
    Repo.all(query)
  end

  @doc """
  Lists all transactions for a specific invoice.

  ## Parameters

  * `invoice_id` - The ID of the invoice to list transactions for
  * `_clinic_id` - (Optional) The ID of the clinic to filter by

  ## Returns

  * List of transactions
  """
  def list_by_invoice(invoice_id, _clinic_id \\ nil) do
    query = Transaction
    |> where(invoice_id: ^invoice_id)
    |> order_by(desc: :inserted_at)

    query = if _clinic_id do
      query |> where(_clinic_id: ^_clinic_id)
    else
      query
    end

    Repo.all(query)
  end

  @doc """
  Lists all transactions for a specific patient within a clinic.

  ## Parameters

  * `patient_id` - The ID of the patient to list transactions for
  * `_clinic_id` - The ID of the clinic to filter by

  ## Returns

  * List of transactions
  """
  def list_by_patient(patient_id, _clinic_id) do
    Transaction
    |> where(patient_id: ^patient_id)
    |> where(_clinic_id: ^_clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all transactions with a specific status within a clinic.

  ## Parameters

  * `status` - The status to filter by ("pending", "completed", "failed")
  * `_clinic_id` - The ID of the clinic to filter by

  ## Returns

  * List of transactions
  """
  def list_by_status(status, _clinic_id) do
    Transaction
    |> where(status: ^status)
    |> where(_clinic_id: ^_clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all transactions within a date range for a specific clinic.

  ## Parameters

  * `start_date` - The start date to filter by
  * `end_date` - The end date to filter by
  * `_clinic_id` - The ID of the clinic to filter by

  ## Returns

  * List of transactions
  """
  def list_by_date_range(start_date, end_date, _clinic_id) do
    Transaction
    |> where(_clinic_id: ^_clinic_id)
    |> where([t], t.inserted_at >= ^start_date)
    |> where([t], t.inserted_at <= ^end_date)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a _transaction by ID and clinic ID to ensure proper isolation.

  ## Parameters

  * `id` - The ID of the _transaction to get
  * `_clinic_id` - The clinic ID to ensure proper isolation

  ## Returns

  * `_transaction` - If found and belongs to the clinic
  * `nil` - If not found or doesn't belong to the clinic
  """
  def get_by_id_and_clinic(id, _clinic_id) do
    Repo.get_by(Transaction, id: id, _clinic_id: _clinic_id)
  end

  @doc """
  Gets a _transaction by _transaction ID.

  ## Parameters

  * `transaction_id` - The _transaction ID to search for
  * `_clinic_id` - Optional clinic ID to ensure proper isolation

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_transaction_id(transaction_id, _clinic_id \\ nil) do
    query = from t in Transaction, where: t.transaction_id == ^transaction_id
    query = if _clinic_id, do: where(query, [t], t._clinic_id == ^_clinic_id), else: query
    Repo.one(query)
  end

  @doc """
  Counts transactions for a specific clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to count transactions for

  ## Returns

  * Count of transactions
  """
  def count_by_clinic(_clinic_id) do
    Transaction
    |> where(_clinic_id: ^_clinic_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Counts transactions for a specific clinic and status.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to count transactions for
  * `status` - The status to filter by

  ## Returns

  * Count of transactions
  """
  def count_by_clinic_and_status(_clinic_id, status) do
    Transaction
    |> where(_clinic_id: ^_clinic_id)
    |> where(status: ^status)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Sums the amount of completed transactions for a specific clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to sum transactions for
  * `status` - The status to filter by (usually "completed")

  ## Returns

  * Sum of _transaction amounts
  """
  def sum_amount_by_clinic_and_status(_clinic_id, status) do
    result = Transaction
    |> where(_clinic_id: ^_clinic_id)
    |> where(status: ^status)
    |> Repo.aggregate(:sum, :amount)
    
    result || 0.0
  end

  @doc """
  Paginates transactions for a specific clinic with filtering.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to list transactions for
  * `filters` - Map of filters to apply (status, invoice_id, patient_id, from_date, to_date)
  * `_page` - Page number for pagination
  * `_per_page` - Number of items per _page

  ## Returns

  * `{transactions, pagination}` - List of transactions and pagination info
  """
  def paginate_by_clinic(_clinic_id, filters \\ %{}, _page \\ 1, _per_page \\ 20) do
    query = Transaction
    |> where(_clinic_id: ^_clinic_id)
    |> apply_filters(filters)
    |> order_by(desc: :inserted_at)

    # Get total count for pagination
    total_count = Repo.aggregate(query, :count, :id)
    total_pages = ceil(total_count / _per_page)

    # Apply pagination
    transactions = query
    |> limit(^_per_page)
    |> offset(^((_page - 1) * _per_page))
    |> Repo.all()

    # Return transactions with pagination info
    {transactions, %{
      _page: _page,
      _per_page: _per_page,
      total_count: total_count,
      total_pages: total_pages
    }}
  end

  # Private functions

  defp changeset(_transaction, attrs) do
    _transaction
    |> cast(attrs, [
      :_clinic_id, :invoice_id, :patient_id, :phone_number, :amount, :status,
      :reference, :checkout_request_id, :merchant_request_id, :transaction_id,
      :transaction_date, :result_code, :result_desc
    ])
    |> validate_required([:_clinic_id, :invoice_id, :patient_id, :phone_number, :amount, :status])
    |> validate_inclusion(:status, ["pending", "completed", "failed"])
    |> validate_number(:amount, greater_than: 0)
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, nil}, query -> query
      {:status, ""}, query -> query
      {:status, status}, query -> where(query, [t], t.status == ^status)
      
      {:invoice_id, nil}, query -> query
      {:invoice_id, ""}, query -> query
      {:invoice_id, invoice_id}, query -> where(query, [t], t.invoice_id == ^invoice_id)
      
      {:patient_id, nil}, query -> query
      {:patient_id, ""}, query -> query
      {:patient_id, patient_id}, query -> where(query, [t], t.patient_id == ^patient_id)
      
      {:from_date, nil}, query -> query
      {:from_date, from_date}, query -> where(query, [t], t.inserted_at >= ^from_date)
      
      {:to_date, nil}, query -> query
      {:to_date, to_date}, query -> 
        # Add a day to include the entire end date
        to_date = 
          to_date
          |> NaiveDateTime.new!(~T[23:59:59])
        where(query, [t], t.inserted_at <= ^to_date)
      
      _, query -> query
    end)
  end
end
