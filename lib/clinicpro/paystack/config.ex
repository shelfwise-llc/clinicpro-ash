defmodule Clinicpro.Paystack.Config do
  @moduledoc """
  Module for managing Paystack configurations for clinics.

  This module provides functions for creating, updating, retrieving, and managing
  Paystack configurations for clinics, following the multi-tenant architecture pattern.

  Each clinic can have multiple configurations, but only one can be active at a time.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo
  alias __MODULE__

  schema "paystack_configs" do
    field :_clinic_id, :integer
    field :environment, :string
    field :public_key, :string
    field :secret_key, :string
    field :webhook_secret, :string
    field :active, :boolean, default: false

    timestamps()
  end

  @doc """
  Creates a changeset for a Paystack configuration.
  """
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:_clinic_id, :environment, :public_key, :secret_key, :webhook_secret, :active])
    |> validate_required([:_clinic_id, :environment, :public_key, :secret_key])
    |> validate_inclusion(:environment, ["test", "production"])
    |> unique_constraint([:_clinic_id, :public_key])
    |> maybe_deactivate_other_configs()
  end

  @doc """
  Creates a new Paystack configuration for a clinic.

  ## Parameters

  * `attrs` - Attributes for the new configuration

  ## Returns

  * `{:ok, config}` - The created configuration
  * `{:error, changeset}` - Error changeset

  """
  def create(attrs) do
    %Config{}
    |> changeset(attrs)
    |> Repo.insert()
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
  def update(config, attrs) do
    # Handle special case for secret_key and webhook_secret
    attrs = handle_sensitive_fields(attrs, config)

    config
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a Paystack configuration by ID.

  ## Parameters

  * `id` - ID of the configuration

  ## Returns

  * `{:ok, config}` - The configuration
  * `{:error, :not_found}` - Configuration not found

  """
  def get(id) do
    case Repo.get(Config, id) do
      nil -> {:error, :not_found}
      config -> {:ok, config}
    end
  end

  @doc """
  Gets the active Paystack configuration for a clinic.

  ## Parameters

  * `_clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, config}` - The active configuration
  * `{:error, :not_found}` - No active configuration found

  """
  def get_active(_clinic_id) do
    case Repo.one(from c in Config, where: c._clinic_id == ^_clinic_id and c.active == true) do
      nil -> {:error, :not_found}
      config -> {:ok, config}
    end
  end

  @doc """
  Lists all Paystack configurations for a clinic.

  ## Parameters

  * `_clinic_id` - ID of the clinic

  ## Returns

  * List of configurations

  """
  def list_by_clinic(_clinic_id) do
    Repo.all(
      from c in Config,
        where: c._clinic_id == ^_clinic_id,
        order_by: [desc: c.active, desc: c.inserted_at]
    )
  end

  @doc """
  Activates a Paystack configuration and deactivates all others for the clinic.

  ## Parameters

  * `id` - ID of the configuration to activate

  ## Returns

  * `{:ok, config}` - The activated configuration
  * `{:error, reason}` - Error reason

  """
  def activate(id) do
    Repo._transaction(fn ->
      with {:ok, config} <- get(id),
           :ok <- deactivate_all_for_clinic(config._clinic_id),
           {:ok, updated_config} <- Repo.update(changeset(config, %{is_active: true})) do
        updated_config
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Deactivates a Paystack configuration.

  ## Parameters

  * `id` - ID of the configuration to deactivate

  ## Returns

  * `{:ok, config}` - The deactivated configuration
  * `{:error, reason}` - Error reason

  """
  def deactivate(id) do
    with {:ok, config} <- get(id) do
      Repo.update(changeset(config, %{is_active: false}))
    end
  end

  @doc """
  Deletes a Paystack configuration.

  ## Parameters

  * `id` - ID of the configuration to delete

  ## Returns

  * `{:ok, config}` - The deleted configuration
  * `{:error, reason}` - Error reason

  """
  def delete(id) do
    with {:ok, config} <- get(id) do
      Repo.delete(config)
    end
  end

  # Private functions

  # If secret_key or webhook_secret are empty, keep the existing values
  defp handle_sensitive_fields(attrs, config) do
    attrs
    |> handle_sensitive_field(:secret_key, config)
    |> handle_sensitive_field(:webhook_secret, config)
  end

  defp handle_sensitive_field(attrs, field, config) do
    case Map.get(attrs, field) do
      nil -> attrs
      "" -> Map.put(attrs, field, Map.get(config, field))
      _unused -> attrs
    end
  end

  # Deactivate all other configs for the clinic if this one is being activated
  defp maybe_deactivate_other_configs(changeset) do
    case get_change(changeset, :is_active) do
      true ->
        _clinic_id = get_field(changeset, :_clinic_id)
        deactivate_all_for_clinic(_clinic_id)
        changeset

      _unused ->
        changeset
    end
  end

  # Deactivate all configs for a clinic
  defp deactivate_all_for_clinic(_clinic_id) do
    from(c in Config, where: c._clinic_id == ^_clinic_id)
    |> Repo.update_all(set: [is_active: false])

    :ok
  end

  @doc """
  Gets the secret key from the active configuration for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, secret_key}` - The secret key from the active configuration
  * `{:error, :not_found}` - No active configuration found
  * `{:error, :no_secret_key}` - Active configuration found but no secret key

  """
  def get_secret_key(clinic_id) do
    case get_active(clinic_id) do
      {:ok, config} when is_binary(config.secret_key) and config.secret_key != "" ->
        {:ok, config.secret_key}
      {:ok, _} ->
        {:error, :no_secret_key}
      error ->
        error
    end
  end
end
