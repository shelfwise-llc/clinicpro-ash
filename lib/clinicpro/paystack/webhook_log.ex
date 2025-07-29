defmodule Clinicpro.Paystack.WebhookLog do
  @moduledoc """
  Schema for storing Paystack webhook events.

  This module tracks all incoming webhook events from Paystack,
  their processing status, and related _transaction information.
  It maintains proper multi-tenant isolation through clinic_id.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  # # alias Clinicpro.Repo
  alias Clinicpro.Paystack.Transaction

  schema "paystack_webhook_logs" do
    field :event_type, :string
    field :reference, :string
    field :payload, :map
    field :status, Ecto.Enum, values: [:pending, :processed, :failed]
    field :error_message, :string
    field :processing_time_ms, :integer

    # Multi-tenant field
    field :clinic_id, :integer

    # Associations
    belongs_to :_transaction, Transaction

    # Processing history as embedded schema
    embeds_many :processing_history, ProcessingHistory do
      field :status, Ecto.Enum, values: [:started, :completed, :failed]
      field :message, :string
      field :timestamp, :utc_datetime
    end

    timestamps()
  end

  @required_fields [:event_type, :reference, :payload, :status, :clinic_id]
  @optional_fields [:error_message, :processing_time_ms, :transaction_id]

  @doc """
  Creates a changeset for a new webhook log entry.
  """
  def changeset(webhook_log, attrs) do
    webhook_log
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:processing_history, with: &processing_history_changeset/2)
    |> foreign_key_constraint(:transaction_id)
  end

  defp processing_history_changeset(schema, params) do
    schema
    |> cast(params, [:status, :message, :timestamp])
    |> validate_required([:status, :timestamp])
  end

  @doc """
  Creates a new webhook log entry.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing webhook log entry.
  """
  def update(webhook_log, attrs) do
    webhook_log
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a webhook log by ID, ensuring clinic isolation.
  """
  def get(id, clinic_id) do
    query =
      from w in __MODULE__,
        where: w.id == ^id and w.clinic_id == ^clinic_id

    case Repo.one(query) do
      nil -> {:error, :not_found}
      webhook_log -> {:ok, webhook_log}
    end
  end

  @doc """
  Lists webhook logs for a clinic with optional filtering and pagination.
  """
  def list(clinic_id, filters \\ %{}, page \\ 1, _perpage \\ 20) do
    query =
      from w in __MODULE__,
        where: w.clinic_id == ^clinic_id,
        order_by: [desc: w.inserted_at]

    # Apply filters
    query = apply_filters(query, filters)

    # Get total count
    total_count = Repo.aggregate(query, :count, :id)

    # Apply pagination
    query =
      query
      |> limit(^_perpage)
      |> offset(^((page - 1) * _perpage))

    # Execute query
    webhook_logs = Repo.all(query)

    {webhook_logs, total_count}
  end

  @doc """
  Gets a webhook log with its associated _transaction.
  """
  def get_with_transaction(id, clinic_id) do
    query =
      from w in __MODULE__,
        where: w.id == ^id and w.clinic_id == ^clinic_id,
        preload: [:_transaction]

    case Repo.one(query) do
      nil -> {:error, :not_found}
      webhook_log -> {:ok, webhook_log}
    end
  end

  @doc """
  Marks a webhook as processed with the given _transaction.
  """
  def mark_as_processed(webhook_log, transaction_id, processing_time_ms) do
    # Create processing history entry
    history_entry = %{
      status: :completed,
      message: "Webhook processed successfully",
      timestamp: DateTime.utc_now()
    }

    # Update webhook log
    webhook_log
    |> changeset(%{
      status: :processed,
      transaction_id: transaction_id,
      processing_time_ms: processing_time_ms,
      processing_history: webhook_log.processing_history ++ [history_entry]
    })
    |> Repo.update()
  end

  @doc """
  Marks a webhook as failed with an error message.
  """
  def mark_as_failed(webhook_log, error_message) do
    # Create processing history entry
    history_entry = %{
      status: :failed,
      message: error_message,
      timestamp: DateTime.utc_now()
    }

    # Update webhook log
    webhook_log
    |> changeset(%{
      status: :failed,
      error_message: error_message,
      processing_history: webhook_log.processing_history ++ [history_entry]
    })
    |> Repo.update()
  end

  @doc """
  Retries processing a failed webhook.
  """
  def retry_processing(webhook_log) do
    # Create processing history entry
    history_entry = %{
      status: :started,
      message: "Retry processing initiated",
      timestamp: DateTime.utc_now()
    }

    # Update webhook log
    {:ok, updated_webhook} =
      webhook_log
      |> changeset(%{
        status: :pending,
        processing_history: webhook_log.processing_history ++ [history_entry]
      })
      |> Repo.update()

    # Return the updated webhook log
    {:ok, updated_webhook}
  end

  # Private functions

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:event_type, ""}, query ->
        query

      {:event_type, event_type}, query ->
        from q in query, where: q.event_type == ^event_type

      {:status, ""}, query ->
        query

      {:status, status}, query when is_atom(status) ->
        from q in query, where: q.status == ^status

      {:status, status}, query when is_binary(status) ->
        status_atom = String.to_existing_atom(status)
        from q in query, where: q.status == ^status_atom

      {:reference, ""}, query ->
        query

      {:reference, reference}, query ->
        from q in query, where: ilike(q.reference, ^"%#{reference}%")

      {:date_from, ""}, query ->
        query

      {:date_from, date_from}, query ->
        from q in query, where: q.inserted_at >= ^date_from

      {:date_to, ""}, query ->
        query

      {:date_to, date_to}, query ->
        from q in query, where: q.inserted_at <= ^date_to

      _unused, query ->
        query
    end)
  end
end
