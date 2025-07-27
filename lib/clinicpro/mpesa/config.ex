defmodule Clinicpro.MPesa.Config do
  @moduledoc """
  Module for handling M-Pesa configurations with multi-tenant support.

  This module provides functions for creating, updating, and retrieving M-Pesa configurations
  for different clinics, ensuring proper isolation in a multi-tenant environment.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Clinicpro.Repo
  alias __MODULE__

  schema "mpesa_configs" do
    field :_clinic_id, :integer
    field :consumer_key, :string
    field :consumer_secret, :string
    field :passkey, :string
    field :shortcode, :string
    field :environment, :string, default: "sandbox"
    field :base_url, :string
    field :callback_url, :string
    field :validation_url, :string
    field :confirmation_url, :string
    field :active, :boolean, default: true

    timestamps()
  end

  @doc """
  Creates a new M-Pesa configuration for a clinic.

  ## Parameters

  * `attrs` - Map of attributes for the configuration

  ## Returns

  * `{:ok, config}` - On success
  * `{:error, changeset}` - On failure
  """
  def create(attrs) do
    %Config{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing M-Pesa configuration.

  ## Parameters

  * `config` - The configuration to update
  * `attrs` - Map of attributes to update

  ## Returns

  * `{:ok, config}` - On success
  * `{:error, changeset}` - On failure
  """
  def update(config, attrs) do
    config
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a configuration by ID.

  ## Parameters

  * `id` - The ID of the configuration to get

  ## Returns

  * `config` - If found
  * `nil` - If not found
  """
  def get_by_id(id) do
    Repo.get(Config, id)
  end

  @doc """
  Gets the active configuration for a clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to get the configuration for

  ## Returns

  * `{:ok, config}` - If an active configuration was found
  * `{:error, :no_active_config}` - If no active configuration was found
  """
  def get_active_config(_clinic_id) do
    case Repo.get_by(Config, _clinic_id: _clinic_id, active: true) do
      nil -> {:error, :no_active_config}
      config -> {:ok, config}
    end
  end

  @doc """
  Gets any configuration for a clinic (active or inactive).

  ## Parameters

  * `_clinic_id` - The ID of the clinic to get the configuration for

  ## Returns

  * `config` - If found
  * `nil` - If not found
  """
  def get_config(_clinic_id) do
    Repo.get_by(Config, _clinic_id: _clinic_id)
  end

  @doc """
  Lists all configurations.

  ## Returns

  * List of configurations
  """
  def list_configs do
    Config
    |> order_by(asc: :_clinic_id)
    |> Repo.all()
  end

  @doc """
  Lists all configurations for a specific clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to list configurations for

  ## Returns

  * List of configurations
  """
  def list_configs(_clinic_id) do
    Config
    |> where(_clinic_id: ^_clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Activates a configuration.

  This will deactivate all other configurations for the same clinic.

  ## Parameters

  * `id` - The ID of the configuration to activate

  ## Returns

  * `{:ok, config}` - On success
  * `{:error, changeset}` - On failure
  """
  def activate(id) do
    config = get_by_id(id)

    if config do
      # Deactivate all other configs for this clinic
      from(c in Config, where: c._clinic_id == ^config._clinic_id and c.id != ^id)
      |> Repo.update_all(set: [active: false])

      # Activate this config
      config
      |> Ecto.Changeset.change(%{active: true})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Deactivates a configuration.

  ## Parameters

  * `id` - The ID of the configuration to deactivate

  ## Returns

  * `{:ok, config}` - On success
  * `{:error, changeset}` - On failure
  """
  def deactivate(id) do
    config = get_by_id(id)

    if config do
      config
      |> Ecto.Changeset.change(%{active: false})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Gets the shortcode for a clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to get the shortcode for

  ## Returns

  * `{:ok, shortcode}` - If found
  * `{:error, :no_config}` - If no configuration was found
  """
  def get_shortcode(_clinic_id) do
    case get_active_config(_clinic_id) do
      {:ok, config} -> {:ok, config.shortcode}
      {:error, _unused} -> {:error, :no_config}
    end
  end

  @doc """
  Gets the clinic ID for a shortcode.

  ## Parameters

  * `shortcode` - The shortcode to get the clinic ID for

  ## Returns

  * `{:ok, _clinic_id}` - If found
  * `{:error, :not_found}` - If not found
  """
  def get_clinic_id_from_shortcode(shortcode) do
    case Repo.get_by(Config, shortcode: shortcode) do
      nil -> {:error, :not_found}
      config -> {:ok, config._clinic_id}
    end
  end

  # Private functions

  defp changeset(config, attrs) do
    config
    |> cast(attrs, [
      :_clinic_id,
      :consumer_key,
      :consumer_secret,
      :passkey,
      :shortcode,
      :environment,
      :base_url,
      :callback_url,
      :validation_url,
      :confirmation_url,
      :active
    ])
    |> validate_required([
      :_clinic_id,
      :consumer_key,
      :consumer_secret,
      :passkey,
      :shortcode,
      :environment,
      :base_url
    ])
    |> validate_inclusion(:environment, ["sandbox", "production"])
    |> unique_constraint([:shortcode, :environment])
  end
end
