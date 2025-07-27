defmodule Clinicpro.Paystack.Transaction do
  @moduledoc """
  Module for handling Paystack transactions with multi-tenant support.

  This module provides functions for creating, updating, and retrieving payment transactions
  for different clinics, ensuring proper isolation in a multi-tenant environment.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Clinicpro.Repo
  alias __MODULE__

  schema "paystack_transactions" do
    field :_clinic_id, :integer
    field :email, :string
    field :amount, :integer
    field :reference, :string
    field :paystack_reference, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :authorization_url, :string
    field :access_code, :string
    field :payment_date, :utc_datetime
    field :channel, :string
    field :currency, :string
    field :fees, :integer
    field :gateway_response, :string
    field :metadata, :map, default: %{}

    timestamps()
  end

  @doc """
  Creates a new _transaction.

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
  Updates an existing _transaction.

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
  Gets a _transaction by reference and clinic ID.

  ## Parameters

  * `reference` - The reference of the _transaction to get
  * `_clinic_id` - The ID of the clinic that initiated the _transaction

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_reference(reference, _clinic_id) do
    Repo.get_by(Transaction, reference: reference, _clinic_id: _clinic_id)
  end

  @doc """
  Gets a _transaction by Paystack reference and clinic ID.

  ## Parameters

  * `paystack_reference` - The Paystack reference of the _transaction to get
  * `_clinic_id` - The ID of the clinic that initiated the _transaction

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_paystack_reference(paystack_reference, _clinic_id) do
    Repo.get_by(Transaction, paystack_reference: paystack_reference, _clinic_id: _clinic_id)
  end

  @doc """
  Lists all transactions.

  ## Returns

  * List of transactions
  """
  def list_transactions do
    Transaction
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all transactions for a specific clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to list transactions for

  ## Returns

  * List of transactions
  """
  def list_transactions(_clinic_id) do
    Transaction
    |> where(_clinic_id: ^_clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all transactions with a specific status.

  ## Parameters

  * `status` - The status to filter by (e.g., "pending", "completed", "failed")

  ## Returns

  * List of transactions
  """
  def list_transactions_by_status(status) do
    Transaction
    |> where(status: ^status)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all transactions for a specific clinic with a specific status.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to list transactions for
  * `status` - The status to filter by (e.g., "pending", "completed", "failed")

  ## Returns

  * List of transactions
  """
  def list_transactions_by_status(_clinic_id, status) do
    Transaction
    |> where(_clinic_id: ^_clinic_id, status: ^status)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets _transaction statistics for a specific clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to get statistics for

  ## Returns

  * Map with statistics (total_transactions, total_amount, completed_transactions, completed_amount)
  """
  def get_statistics(_clinic_id) do
    # Get total transactions and amount
    total_query =
      from t in Transaction,
        where: t._clinic_id == ^_clinic_id,
        select: %{
          count: count(t.id),
          amount: sum(t.amount)
        }

    # Get completed transactions and amount
    completed_query =
      from t in Transaction,
        where: t._clinic_id == ^_clinic_id and t.status == "completed",
        select: %{
          count: count(t.id),
          amount: sum(t.amount)
        }

    total_stats = Repo.one(total_query) || %{count: 0, amount: 0}
    completed_stats = Repo.one(completed_query) || %{count: 0, amount: 0}

    %{
      total_transactions: total_stats.count,
      total_amount: total_stats.amount || 0,
      completed_transactions: completed_stats.count,
      completed_amount: completed_stats.amount || 0
    }
  end

  # Private functions

  defp changeset(_transaction, attrs) do
    _transaction
    |> cast(attrs, [
      :_clinic_id,
      :email,
      :amount,
      :reference,
      :paystack_reference,
      :description,
      :status,
      :authorization_url,
      :access_code,
      :payment_date,
      :channel,
      :currency,
      :fees,
      :gateway_response,
      :metadata
    ])
    |> validate_required([
      :_clinic_id,
      :email,
      :amount,
      :reference,
      :description,
      :status
    ])
    |> unique_constraint(:reference)
    |> unique_constraint(:paystack_reference)
  end
end
