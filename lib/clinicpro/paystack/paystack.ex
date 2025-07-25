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
  * `reference` - Optional custom reference (if not provided, one will be generated)
  * `description` - Description of the payment
  * `_clinic_id` - ID of the clinic
  * `_opts` - Additional options:
    * `:callback_url` - URL to redirect to after payment
    * `:metadata` - Additional data to include with the _transaction
    * `:use_subaccount` - Whether to use the active subaccount

  ## Returns

  * `{:ok, %{_transaction: _transaction, authorization_url: url}}` - Success
  * `{:error, reason}` - Error reason

  """
  def initialize_payment(email, amount, reference \\ nil, description, _clinic_id, _opts \\ []) do
    # Generate a reference if not provided
    reference = reference || generate_reference(_clinic_id)

    # Extract options
    callback_url = Keyword.get(_opts, :callback_url)
    metadata = Keyword.get(_opts, :metadata)
    use_subaccount = Keyword.get(_opts, :use_subaccount, false)

    # Initialize the payment
    Transaction.initialize_payment(
      email,
      amount,
      description,
      _clinic_id,
      callback_url,
      metadata,
      use_subaccount
    )
  end

  @doc """
  Verifies a payment _transaction with Paystack.

  ## Parameters

  * `reference` - Transaction reference to verify
  * `_clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, _transaction}` - The verified _transaction
  * `{:error, reason}` - Error reason

  """
  def verify_payment(reference, _clinic_id) do
    Transaction.verify_payment(reference, _clinic_id)
  end

  @doc """
  Processes a webhook callback from Paystack.

  ## Parameters

  * `payload` - The raw payload from the webhook
  * `signature` - The X-Paystack-Signature header value
  * `_clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, _transaction}` - Successfully processed callback
  * `{:error, reason}` - Error reason

  """
  def process_webhook(payload, signature, _clinic_id) do
    Callback.process_webhook(payload, signature, _clinic_id)
  end

  @doc """
  Gets _transaction statistics for a clinic.

  ## Parameters

  * `_clinic_id` - ID of the clinic

  ## Returns

  * Map with _transaction statistics

  """
  def get_transaction_stats(_clinic_id) do
    Transaction.get_stats(_clinic_id)
  end

  @doc """
  Lists all transactions for a clinic.

  ## Parameters

  * `_clinic_id` - ID of the clinic
  * `limit` - Maximum number of transactions to return (default: 50)
  * `offset` - Number of transactions to skip (default: 0)

  ## Returns

  * List of transactions

  """
  def list_transactions(_clinic_id, limit \\ 50, offset \\ 0) do
    Transaction.list_by_clinic(_clinic_id, limit, offset)
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

  * `_clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, config}` - The active configuration
  * `{:error, :not_found}` - No active configuration found

  """
  def get_active_config(_clinic_id) do
    Config.get_active(_clinic_id)
  end

  @doc """
  Lists all Paystack configurations for a clinic.

  ## Parameters

  * `_clinic_id` - ID of the clinic

  ## Returns

  * List of configurations

  """
  def list_configs(_clinic_id) do
    Config.list_by_clinic(_clinic_id)
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
  Gets the active Paystack subaccount for a clinic.

  ## Parameters

  * `_clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, subaccount}` - The active subaccount
  * `{:error, :not_found}` - No active subaccount found

  """
  def get_active_subaccount(_clinic_id) do
    Subaccount.get_active(_clinic_id)
  end

  @doc """
  Lists all Paystack subaccounts for a clinic.

  ## Parameters

  * `_clinic_id` - ID of the clinic

  ## Returns

  * List of subaccounts

  """
  def list_subaccounts(_clinic_id) do
    Subaccount.list_by_clinic(_clinic_id)
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
  Lists banks available on Paystack.

  ## Parameters

  * `_clinic_id` - ID of the clinic
  * `country` - Country code (default: "nigeria")

  ## Returns

  * `{:ok, banks}` - List of banks
  * `{:error, reason}` - Error reason

  """
  def list_banks(_clinic_id, country \\ "nigeria") do
    API.list_banks(_clinic_id, country)
  end

  # Private functions

  defp generate_reference(_clinic_id) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :rand.uniform(1_000_000)
    "paystack_#{_clinic_id}_#{timestamp}_#{random}"
  end
end
