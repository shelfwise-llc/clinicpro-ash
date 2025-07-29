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
    field :clinic_id, :integer
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
  def update_transaction(transaction, attrs) do
    transaction
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
  Gets a transaction by ID and clinic ID.

  ## Parameters

  * `id` - The ID of the transaction to get
  * `clinic_id` - The ID of the clinic that initiated the transaction

  ## Returns

  * `{:ok, transaction}` - If found
  * `{:error, :not_found}` - If not found
  """
  def get_by_id_and_clinic(id, clinic_id) do
    case Repo.get_by(Transaction, id: id, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  @doc """
  Gets a _transaction by reference and clinic ID.

  ## Parameters

  * `reference` - The reference of the _transaction to get
  * `clinic_id` - The ID of the clinic that initiated the _transaction

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_reference(reference, clinic_id) do
    Repo.get_by(Transaction, reference: reference, clinic_id: clinic_id)
  end

  @doc """
  Gets a _transaction by Paystack reference and clinic ID.

  ## Parameters

  * `paystack_reference` - The Paystack reference of the _transaction to get
  * `clinic_id` - The ID of the clinic that initiated the _transaction

  ## Returns

  * `_transaction` - If found
  * `nil` - If not found
  """
  def get_by_paystack_reference(paystack_reference, clinic_id) do
    Repo.get_by(Transaction, paystack_reference: paystack_reference, clinic_id: clinic_id)
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

  * `clinic_id` - The ID of the clinic to list transactions for

  ## Returns

  * List of transactions
  """
  def list_transactions(clinic_id) do
    Transaction
    |> where(clinic_id: ^clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists transactions for a clinic with pagination and filtering.

  ## Parameters

  * `clinic_id` - The ID of the clinic to list transactions for
  * `limit` - Maximum number of transactions to return
  * `offset` - Number of transactions to skip
  * `filters` - Map of filters to apply

  ## Returns

  * List of transactions
  """
  def list_by_clinic(clinic_id, limit \\ 50, offset \\ 0, filters \\ %{}) do
    query =
      Transaction
      |> where(clinic_id: ^clinic_id)

    # Apply filters if provided
    query = apply_filters(query, filters)

    query
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Counts transactions for a clinic with filtering.

  ## Parameters

  * `clinic_id` - The ID of the clinic to count transactions for
  * `filters` - Map of filters to apply

  ## Returns

  * Count of transactions
  """
  def count_by_clinic(clinic_id, filters \\ %{}) do
    query =
      Transaction
      |> where(clinic_id: ^clinic_id)

    # Apply filters if provided
    query = apply_filters(query, filters)

    Repo.aggregate(query, :count, :id)
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

  * `clinic_id` - The ID of the clinic to list transactions for
  * `status` - The status to filter by (e.g., "pending", "completed", "failed")

  ## Returns

  * List of transactions
  """
  def list_transactions_by_status(clinic_id, status) do
    Transaction
    |> where(clinic_id: ^clinic_id, status: ^status)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets _transaction statistics for a specific clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to get statistics for

  ## Returns

  * Map with statistics (total_transactions, total_amount, completed_transactions, completed_amount)
  """
  def get_statistics(clinic_id) do
    # Get total transactions and amount
    total_query =
      from t in Transaction,
        where: t.clinic_id == ^clinic_id,
        select: %{
          count: count(t.id),
          amount: sum(t.amount)
        }

    # Get completed transactions and amount
    completed_query =
      from t in Transaction,
        where: t.clinic_id == ^clinic_id and t.status == "completed",
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

  defp changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :clinic_id,
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
      :clinic_id,
      :email,
      :amount,
      :reference,
      :description,
      :status
    ])
    |> unique_constraint(:reference)
    |> unique_constraint(:paystack_reference)
  end

  # Helper function to apply filters to a query
  defp apply_filters(query, %{status: status}) when is_binary(status) do
    query |> where(status: ^status)
  end

  defp apply_filters(query, _), do: query

  defp apply_filters(query, filters) when map_size(filters) == 0, do: query

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"status", value}, query when is_binary(value) and value != "" ->
        where(query, [t], t.status == ^value)

      {"reference", value}, query when is_binary(value) and value != "" ->
        where(query, [t], ilike(t.reference, ^"%#{value}%"))

      {"email", value}, query when is_binary(value) and value != "" ->
        where(query, [t], ilike(t.email, ^"%#{value}%"))

      {"date_from", value}, query when is_binary(value) and value != "" ->
        case Date.from_iso8601(value) do
          {:ok, date} ->
            where(query, [t], fragment("date(?)", t.inserted_at) >= ^date)

          _ ->
            query
        end

      {"date_to", value}, query when is_binary(value) and value != "" ->
        case Date.from_iso8601(value) do
          {:ok, date} ->
            where(query, [t], fragment("date(?)", t.inserted_at) <= ^date)

          _ ->
            query
        end

      _, query ->
        query
    end)
  end

  @doc """
  Gets transaction statistics for a clinic.

  ## Parameters

  * `clinic_id` - The ID of the clinic to get statistics for

  ## Returns

  * Map containing transaction statistics
  """
  def get_stats(clinic_id) do
    # Get total transactions
    total = count_by_clinic(clinic_id)

    # Get successful transactions
    successful = count_by_clinic(clinic_id, %{status: "success"})

    # Get pending transactions
    pending = count_by_clinic(clinic_id, %{status: "pending"})

    # Get failed transactions
    failed = count_by_clinic(clinic_id, %{status: "failed"})

    # Calculate total amount from successful transactions
    total_amount =
      Transaction
      |> where(clinic_id: ^clinic_id, status: "success")
      |> select([t], sum(t.amount))
      |> Repo.one()
      |> Kernel.|||(0)

    %{
      total: total,
      successful: successful,
      pending: pending,
      failed: failed,
      total_amount: total_amount
    }
  end

  @doc """
  Initialize a payment transaction with Paystack.

  ## Parameters

  * `email` - Customer email
  * `amount` - Amount in kobo/cents
  * `reference` - Unique transaction reference
  * `callback_url` - URL to redirect to after payment
  * `metadata` - Additional data to include with the transaction
  * `description` - Description of the transaction
  * `subaccount` - Optional subaccount to split payment with
  * `clinic_id` - ID of the clinic processing the payment

  ## Returns

  * `{:ok, transaction}` - On success
  * `{:error, reason}` - On failure
  """
  def initialize_payment(email, amount, reference, callback_url, metadata, description, subaccount \\ nil, clinic_id) do
    # Create a transaction record first
    attrs = %{
      email: email,
      amount: amount,
      reference: reference,
      description: description,
      clinic_id: clinic_id,
      metadata: metadata
    }

    with {:ok, transaction} <- create(attrs),
         {:ok, paystack_response} <- Clinicpro.Paystack.API.initialize_transaction(
           email,
           amount,
           reference,
           callback_url,
           metadata,
           subaccount,
           clinic_id
         ) do
      # Extract data from Paystack response
      data = paystack_response["data"]
      
      # Update transaction with Paystack response data
      attrs = %{
        authorization_url: data["authorization_url"],
        access_code: data["access_code"]
      }
      
      update_transaction(transaction, attrs)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Verify a payment transaction with Paystack.

  ## Parameters

  * `reference` - Transaction reference to verify
  * `clinic_id` - ID of the clinic that processed the payment

  ## Returns

  * `{:ok, transaction}` - On success
  * `{:error, reason}` - On failure
  """
  def verify_payment(reference, clinic_id) do
    # First check if we have this transaction
    case get_by_reference(reference, clinic_id) do
      nil ->
        {:error, :not_found}

      transaction ->
        # Call Paystack API to verify the payment
        with {:ok, paystack_response} <- Clinicpro.Paystack.API.verify_transaction(reference, clinic_id) do
          # Extract relevant data from the response
          data = paystack_response["data"]
          status = if data["status"] == "success", do: "success", else: "failed"
          
          # Update the transaction with verification data
          update_transaction(transaction, %{
            status: status,
            paystack_reference: data["reference"],
            payment_date: data["paid_at"] && DateTime.from_iso8601(data["paid_at"]) |> elem(1),
            channel: data["channel"],
            currency: data["currency"],
            fees: data["fees"],
            gateway_response: data["gateway_response"]
          })
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end
end
