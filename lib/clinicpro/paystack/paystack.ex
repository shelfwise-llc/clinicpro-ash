defmodule Clinicpro.Paystack do
  @moduledoc """
  Main module for Paystack payment integration with multi-tenant support.

  This module serves as the primary entry point for Paystack payment operations,
  including _transaction initialization, verification, and webhook handling.

  It follows a multi-tenant architecture pattern, ensuring proper isolation
  between different clinics' payment processing.
  """

  alias Clinicpro.Paystack.{API, Config, Subaccount, Transaction, Callback}

  @doc """
  Initializes a payment _transaction with Paystack.

  ## Parameters

  * `email` - Customer's email address
  * `amount` - Amount in Naira
  * `payment_ref` - Optional custom reference (if not provided, one will be generated)
  * `description` - Description of the payment
  * `clinic_id` - ID of the clinic
  * `opts` - Additional options:
    * `:callback_url` - URL to redirect to after payment
    * `:metadata` - Additional data to include with the _transaction
    * `:use_subaccount` - Whether to use the active subaccount

  ## Returns

  * `{:ok, %{transaction: transaction, authorization_url: url}}` - Success
  * `{:error, reason}` - Error reason

  """
  def initialize_payment(email, amount, payment_ref \\ nil, description, clinic_id, opts \\ []) do
    # Generate a payment reference if not provided
    final_payment_ref = payment_ref || generate_reference(clinic_id)

    # Extract options
    callback_url = Keyword.get(opts, :callback_url)
    metadata = Keyword.get(opts, :metadata)
    use_subaccount = Keyword.get(opts, :use_subaccount, false)

    # Initialize the payment
    Transaction.initialize_payment(
      email,
      amount,
      final_payment_ref,
      description,
      clinic_id,
      callback_url,
      metadata,
      use_subaccount
    )
  end

  @doc """
  Verifies a payment _transaction with Paystack.

  ## Parameters

  * `payment_reference` - Transaction reference to verify
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, _transaction}` - The verified _transaction
  * `{:error, reason}` - Error reason

  """
  def verify_payment(payment_reference, clinic_id) do
    Transaction.verify_payment(payment_reference, clinic_id)
  end

  @doc """
  Verifies a transaction by ID and clinic ID.

  ## Parameters

  * `id` - ID of the transaction
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, transaction}` - The verified transaction
  * `{:error, reason}` - Error reason

  """
  def verify_transaction(id, clinic_id) do
    with {:ok, transaction} <- Transaction.get_by_id_and_clinic(id, clinic_id),
         {:ok, verified} <- Transaction.verify_payment(transaction.reference, clinic_id) do
      {:ok, verified}
    else
      error -> error
    end
  end

  @doc """
  Processes a webhook callback from Paystack.

  ## Parameters

  * `payload` - The raw payload from the webhook
  * `signature` - The X-Paystack-Signature header value
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, _transaction}` - Successfully processed callback
  * `{:error, reason}` - Error reason

  """
  def process_webhook(payload, signature, clinic_id) do
    Callback.process_webhook(payload, signature, clinic_id)
  end

  @doc """
  Initiates a payment transaction with Paystack using a params map.

  ## Parameters

  * `payment_params` - Map with payment parameters
    * `:email` - Customer's email address
    * `:amount` - Amount in Naira
    * `:reference` - Optional custom reference
    * `:description` - Description of the payment
    * `:clinic_id` - ID of the clinic
    * `:callback_url` - URL to redirect to after payment
    * `:metadata` - Additional data to include with the transaction
    * `:use_subaccount` - Whether to use the active subaccount

  ## Returns

  * `{:ok, %{transaction: transaction, authorization_url: url}}` - Success
  * `{:error, reason}` - Error reason

  """
  def initiate_payment(payment_params) do
    email = Map.get(payment_params, :email) || Map.get(payment_params, "email")
    amount = Map.get(payment_params, :amount) || Map.get(payment_params, "amount")
    reference = Map.get(payment_params, :reference) || Map.get(payment_params, "reference")
    description = Map.get(payment_params, :description) || Map.get(payment_params, "description")
    clinic_id = Map.get(payment_params, :clinic_id) || Map.get(payment_params, "clinic_id")

    opts = [
      callback_url:
        Map.get(payment_params, :callback_url) || Map.get(payment_params, "callback_url"),
      metadata: Map.get(payment_params, :metadata) || Map.get(payment_params, "metadata"),
      use_subaccount:
        Map.get(payment_params, :use_subaccount) || Map.get(payment_params, "use_subaccount") ||
          false
    ]

    initialize_payment(email, amount, reference, description, clinic_id, opts)
  end

  @doc """
  Gets _transaction statistics for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * Map with transaction statistics

  """
  def get_transaction_stats(clinic_id) do
    Transaction.get_stats(clinic_id)
  end

  @doc """
  Lists all transactions for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic
  * `limit` - Maximum number of transactions to return (default: 50)
  * `offset` - Number of transactions to skip (default: 0)

  ## Returns

  * List of transactions

  """
  def list_transactions(clinic_id, limit \\ 50, offset \\ 0) do
    Transaction.list_by_clinic(clinic_id, limit, offset)
  end

  @doc """
  Lists transactions for a clinic with pagination and filtering.

  ## Parameters

  * `clinic_id` - ID of the clinic
  * `page` - Page number (starting from 1)
  * `perpage` - Number of items per page
  * `filters` - Map of filters to apply

  ## Returns

  * `{:ok, %{transactions: transactions, total: total, page: page, perpage: perpage}}` - Success
  * `{:error, reason}` - Error reason

  """
  def list_transactions_paginated(clinic_id, page, perpage, filters \\ %{}) do
    offset = (page - 1) * perpage
    transactions = Transaction.list_by_clinic(clinic_id, perpage, offset, filters)
    total = Transaction.count_by_clinic(clinic_id, filters)

    {:ok,
     %{
       transactions: transactions,
       total: total,
       page: page,
       perpage: perpage
     }}
  end

  @doc """
  Creates a new Paystack configuration for a clinic.

  ## Parameters

  * `attrs` - Attributes for the new configuration

  ## Returns

  * `{:ok, config}` - The created configuration
  * `{:error, changeset}` - Error changeset

  """
  def create_config(attrs) do
    Config.create(attrs)
  end

  @doc """
  Updates an existing Paystack configuration.

  ## Parameters

  * `config` - The configuration to update
  * `attrs` - Attributes to update

  ## Returns

  * `{:ok, config}` - The updated configuration
  * `{:error, changeset}` - Error changeset

  """
  def update_config(config, attrs) do
    Config.update(config, attrs)
  end

  @doc """
  Gets a Paystack configuration by ID.

  ## Parameters

  * `id` - ID of the configuration

  ## Returns

  * `{:ok, config}` - The configuration
  * `{:error, :not_found}` - Configuration not found

  """
  def get_config(id) do
    Config.get(id)
  end

  @doc """
  Gets the active Paystack configuration for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, config}` - The active configuration
  * `{:error, :not_found}` - No active configuration found

  """
  def get_active_config(clinic_id) do
    Config.getactive(clinic_id)
  end

  @doc """
  Lists all Paystack configurations for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * List of configurations

  """
  def list_configs(clinic_id) do
    Config.list_by_clinic(clinic_id)
  end

  @doc """
  Activates a Paystack configuration.

  ## Parameters

  * `id` - ID of the configuration to activate

  ## Returns

  * `{:ok, config}` - The activated configuration
  * `{:error, reason}` - Error reason

  """
  def activate_config(id) do
    Config.activate(id)
  end

  @doc """
  Deactivates a Paystack configuration.

  ## Parameters

  * `id` - ID of the configuration to deactivate

  ## Returns

  * `{:ok, config}` - The deactivated configuration
  * `{:error, reason}` - Error reason

  """
  def deactivate_config(id) do
    Config.deactivate(id)
  end

  @doc """
  Deletes a Paystack configuration.

  ## Parameters

  * `id` - ID of the configuration to delete

  ## Returns

  * `{:ok, config}` - The deleted configuration
  * `{:error, reason}` - Error reason

  """
  def delete_config(id) do
    Config.delete(id)
  end

  @doc """
  Creates a new Paystack subaccount for a clinic.

  ## Parameters

  * `attrs` - Attributes for the new subaccount

  ## Returns

  * `{:ok, subaccount}` - The created subaccount
  * `{:error, changeset}` - Error changeset

  """
  def create_subaccount(attrs) do
    Subaccount.create(attrs)
  end

  @doc """
  Gets a Paystack subaccount by ID.

  ## Parameters

  * `id` - ID of the subaccount

  ## Returns

  * `{:ok, subaccount}` - The subaccount
  * `{:error, :not_found}` - Subaccount not found

  """
  def get_subaccount(id) do
    Subaccount.get(id)
  end

  @doc """
  Gets a Paystack subaccount by ID and clinic ID.

  ## Parameters

  * `id` - ID of the subaccount
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, subaccount}` - The subaccount
  * `{:error, :not_found}` - Subaccount not found

  """
  def get_subaccount(id, clinic_id) do
    Subaccount.get_by_id_and_clinic(id, clinic_id)
  end

  @doc """
  Gets the active Paystack subaccount for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, subaccount}` - The active subaccount
  * `{:error, :not_found}` - No active subaccount found

  """
  def get_active_subaccount(clinic_id) do
    Subaccount.getactive(clinic_id)
  end

  @doc """
  Lists all Paystack subaccounts for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * List of subaccounts

  """
  def list_subaccounts(clinic_id) do
    Subaccount.list_by_clinic(clinic_id)
  end

  @doc """
  Activates a Paystack subaccount.

  ## Parameters

  * `id` - ID of the subaccount to activate

  ## Returns

  * `{:ok, subaccount}` - The activated subaccount
  * `{:error, reason}` - Error reason

  """
  def activate_subaccount(id) do
    Subaccount.activate(id)
  end

  @doc """
  Deactivates a Paystack subaccount.

  ## Parameters

  * `id` - ID of the subaccount to deactivate

  ## Returns

  * `{:ok, subaccount}` - The deactivated subaccount
  * `{:error, reason}` - Error reason

  """
  def deactivate_subaccount(id) do
    Subaccount.deactivate(id)
  end

  @doc """
  Deletes a Paystack subaccount.

  ## Parameters

  * `id` - ID of the subaccount to delete

  ## Returns

  * `{:ok, subaccount}` - The deleted subaccount
  * `{:error, reason}` - Error reason

  """
  def delete_subaccount(id) do
    Subaccount.delete(id)
  end

  @doc """
  Updates a Paystack subaccount.

  ## Parameters

  * `subaccount` - The subaccount to update
  * `attrs` - Attributes to update

  ## Returns

  * `{:ok, subaccount}` - The updated subaccount
  * `{:error, changeset}` - Error changeset

  """
  def update_subaccount(subaccount, attrs) do
    Subaccount.update(subaccount, attrs)
  end

  @doc """
  Lists banks available on Paystack.

  ## Parameters

  * `clinic_id` - ID of the clinic
  * `country` - Country code (default: "nigeria")

  ## Returns

  * `{:ok, banks}` - List of banks
  * `{:error, reason}` - Error reason

  """
  def list_banks(clinic_id, country \\ "nigeria") do
    API.list_banks(clinic_id, country)
  end

  @doc """
  Gets a transaction with its associated webhook events.

  ## Parameters

  * `id` - ID of the transaction
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, %{transaction: transaction, events: events}}` - Success
  * `{:error, reason}` - Error reason

  """
  def get_transaction_with_events(id, clinic_id) do
    with {:ok, transaction} <- Transaction.get_by_id_and_clinic(id, clinic_id),
         events <- Callback.list_events_for_transaction(transaction.id) do
      {:ok, %{transaction: transaction, events: events}}
    else
      error -> error
    end
  end

  # Private functions

  defp generate_reference(clinic_id) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :rand.uniform(1_000_000)
    "paystack_#{clinic_id}_#{timestamp}_#{random}"
  end
end
