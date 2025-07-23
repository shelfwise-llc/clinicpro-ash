defmodule Clinicpro.MPesa.CallbackLog do
  @moduledoc """
  Schema and functions for M-Pesa callback logs with multi-tenant support.
  
  This module provides a schema and functions for storing and retrieving M-Pesa callback logs,
  ensuring proper isolation between clinics in a multi-tenant environment.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Clinicpro.Repo
  alias __MODULE__

  schema "mpesa_callback_logs" do
    field :clinic_id, :integer
    field :type, :string # stk_push, c2b_validation, c2b_confirmation, transaction_status
    field :status, :string # success, failed
    field :reference, :string
    field :shortcode, :string
    field :url, :string
    field :request_payload, :string
    field :response_payload, :string
    field :response_code, :string
    field :response_description, :string
    field :processing_time, :integer
    field :transaction_id, :string

    timestamps()
  end

  @doc """
  Creates a new M-Pesa callback log.

  ## Parameters

  * `attrs` - Map of attributes for the callback log

  ## Returns

  * `{:ok, callback_log}` - On success
  * `{:error, changeset}` - On failure
  """
  def create(attrs) do
    %CallbackLog{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a callback log by ID.

  ## Parameters

  * `id` - The ID of the callback log to get
  * `clinic_id` - The clinic ID to ensure proper isolation

  ## Returns

  * `callback_log` - If found and belongs to the clinic
  * `nil` - If not found or doesn't belong to the clinic
  """
  def get_by_id_and_clinic(id, clinic_id) do
    Repo.get_by(CallbackLog, id: id, clinic_id: clinic_id)
  end

  @doc """
  Lists all callback logs for a specific clinic with optional filtering.

  ## Parameters

  * `clinic_id` - The ID of the clinic to list callback logs for
  * `filters` - Map of filters to apply (type, status, from_date, to_date)
  * `page` - Page number for pagination
  * `per_page` - Number of items per page

  ## Returns

  * `{callback_logs, pagination}` - List of callback logs and pagination info
  """
  def paginate_by_clinic(clinic_id, filters \\ %{}, page \\ 1, per_page \\ 20) do
    query = CallbackLog
    |> where(clinic_id: ^clinic_id)
    |> apply_filters(filters)
    |> order_by(desc: :inserted_at)

    # Get total count for pagination
    total_count = Repo.aggregate(query, :count, :id)
    total_pages = ceil(total_count / per_page)

    # Apply pagination
    callback_logs = query
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
    |> Repo.all()

    # Return callback logs with pagination info
    {callback_logs, %{
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }}
  end

  @doc """
  Lists callback logs for a specific transaction.

  ## Parameters

  * `transaction_id` - The ID of the transaction to list callback logs for
  * `clinic_id` - The clinic ID to ensure proper isolation

  ## Returns

  * List of callback logs
  """
  def list_by_transaction(transaction_id, clinic_id) do
    CallbackLog
    |> where(transaction_id: ^transaction_id)
    |> where(clinic_id: ^clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists callback logs by type for a specific clinic.

  ## Parameters

  * `type` - The type of callback logs to list
  * `clinic_id` - The clinic ID to ensure proper isolation

  ## Returns

  * List of callback logs
  """
  def list_by_type(type, clinic_id) do
    CallbackLog
    |> where(type: ^type)
    |> where(clinic_id: ^clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Private functions

  defp changeset(callback_log, attrs) do
    callback_log
    |> cast(attrs, [
      :clinic_id, :type, :status, :reference, :shortcode, :url, 
      :request_payload, :response_payload, :response_code, 
      :response_description, :processing_time, :transaction_id
    ])
    |> validate_required([:clinic_id, :type, :status, :request_payload])
    |> validate_inclusion(:type, ["stk_push", "c2b_validation", "c2b_confirmation", "transaction_status"])
    |> validate_inclusion(:status, ["success", "failed"])
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:type, nil}, query -> query
      {:type, ""}, query -> query
      {:type, type}, query -> where(query, [c], c.type == ^type)
      
      {:status, nil}, query -> query
      {:status, ""}, query -> query
      {:status, status}, query -> where(query, [c], c.status == ^status)
      
      {:from_date, nil}, query -> query
      {:from_date, from_date}, query -> where(query, [c], c.inserted_at >= ^from_date)
      
      {:to_date, nil}, query -> query
      {:to_date, to_date}, query -> 
        # Add a day to include the entire end date
        to_date = 
          to_date
          |> NaiveDateTime.add(86400, :second)
        where(query, [c], c.inserted_at <= ^to_date)
      
      _, query -> query
    end)
  end
end
