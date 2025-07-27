defmodule Clinicpro.Paystack.SubAccount do
  @moduledoc """
  Module for managing Paystack subaccounts with multi-tenant support.

  This module provides functions for creating, updating, and retrieving Paystack subaccounts
  for different clinics, ensuring proper isolation in a multi-tenant environment.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Clinicpro.Repo
  alias Clinicpro.Paystack.{Config, Http}
  alias __MODULE__

  schema "paystack_subaccounts" do
    field :_clinic_id, :integer
    field :subaccount_code, :string
    field :business_name, :string
    field :settlement_bank, :string
    field :account_number, :string
    field :percentage_charge, :float, default: 0.0
    field :active, :boolean, default: true

    timestamps()
  end

  @doc """
  Creates a new Paystack subaccount for a clinic via the Paystack API.

  ## Parameters

  - `business_name` - The business name for the subaccount
  - `settlement_bank` - The bank code for settlements
  - `account_number` - The account number for settlements
  - `_clinic_id` - The ID of the clinic
  - `percentage_charge` - The percentage charge for the subaccount (optional)

  ## Returns

  - `{:ok, %{subaccount_code: code}}` - If successful
  - `{:error, reason}` - If failed
  """
  def create(business_name, settlement_bank, account_number, clinic_id, percentage_charge \\ nil) do
    with {:ok, secret_key} <- Config.get_secret_key(clinic_id) do
      # Build the payload
      payload =
        %{
          business_name: business_name,
          settlement_bank: settlement_bank,
          account_number: account_number,
          percentage_charge: percentage_charge
        }
        |> remove_nil_values()

      # Make the API call
      case Http.post("/subaccount", payload, secret_key) do
        {:ok, %{"status" => true, "data" => data}} ->
          {:ok, %{subaccount_code: data["subaccount_code"]}}

        {:ok, %{"status" => false, "message" => message}} ->
          {:error, message}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Creates a new subaccount record in the database.

  ## Parameters

  * `attrs` - Map of attributes for the subaccount

  ## Returns

  * `{:ok, subaccount}` - On success
  * `{:error, changeset}` - On failure
  """
  def create(attrs) do
    %SubAccount{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing subaccount.

  ## Parameters

  * `subaccount` - The subaccount to update
  * `attrs` - Map of attributes to update

  ## Returns

  * `{:ok, subaccount}` - On success
  * `{:error, changeset}` - On failure
  """
  def update(subaccount, attrs) do
    subaccount
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a Paystack subaccount via the Paystack API.

  ## Parameters

  - `subaccount_code` - The subaccount code to update
  - `attrs` - Map of attributes to update
  - `_clinic_id` - The ID of the clinic

  ## Returns

  - `{:ok, %{}}` - If successful
  - `{:error, reason}` - If failed
  """
  def update_on_paystack(subaccount_code, attrs, clinic_id) do
    with {:ok, secret_key} <- Config.get_secret_key(clinic_id) do
      # Make the API call
      case Http.put("/subaccount/#{subaccount_code}", remove_nil_values(attrs), secret_key) do
        {:ok, %{"status" => true}} ->
          {:ok, %{}}

        {:ok, %{"status" => false, "message" => message}} ->
          {:error, message}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Gets a subaccount by ID.

  ## Parameters

  * `id` - The ID of the subaccount to get

  ## Returns

  * `subaccount` - If found
  * `nil` - If not found
  """
  def get_by_id(id) do
    Repo.get(SubAccount, id)
  end

  @doc """
  Gets the active subaccount for a clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to get the subaccount for

  ## Returns

  * `{:ok, subaccount}` - If an active subaccount was found
  * `{:error, :no_active_subaccount}` - If no active subaccount was found
  """
  def get_active_subaccount(clinic_id) do
    case Repo.get_by(SubAccount, _clinic_id: clinic_id, active: true) do
      nil -> {:error, :no_active_subaccount}
      subaccount -> {:ok, subaccount}
    end
  end

  @doc """
  Lists all subaccounts.

  ## Returns

  * List of subaccounts
  """
  def list_subaccounts do
    SubAccount
    |> order_by(asc: :_clinic_id)
    |> Repo.all()
  end

  @doc """
  Lists all subaccounts for a specific clinic.

  ## Parameters

  * `_clinic_id` - The ID of the clinic to list subaccounts for

  ## Returns

  * List of subaccounts
  """
  def list_subaccounts(clinic_id) do
    SubAccount
    |> where(_clinic_id: ^clinic_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Activates a subaccount.

  This will deactivate all other subaccounts for the same clinic.

  ## Parameters

  * `id` - The ID of the subaccount to activate

  ## Returns

  * `{:ok, subaccount}` - On success
  * `{:error, changeset}` - On failure
  """
  def activate(id) do
    subaccount = get_by_id(id)

    if subaccount do
      # Deactivate all other subaccounts for this clinic
      from(s in SubAccount, where: s._clinic_id == ^subaccount._clinic_id and s.id != ^id)
      |> Repo.update_all(set: [active: false])

      # Activate this subaccount
      subaccount
      |> Ecto.Changeset.change(%{active: true})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Deactivates a subaccount.

  ## Parameters

  * `id` - The ID of the subaccount to deactivate

  ## Returns

  * `{:ok, subaccount}` - On success
  * `{:error, changeset}` - On failure
  """
  def deactivate(id) do
    subaccount = get_by_id(id)

    if subaccount do
      subaccount
      |> Ecto.Changeset.change(%{active: false})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  # Private functions

  defp changeset(subaccount, attrs) do
    subaccount
    |> cast(attrs, [
      :_clinic_id,
      :subaccount_code,
      :business_name,
      :settlement_bank,
      :account_number,
      :percentage_charge,
      :active
    ])
    |> validate_required([
      :_clinic_id,
      :subaccount_code,
      :business_name,
      :settlement_bank,
      :account_number
    ])
    |> unique_constraint(:subaccount_code)
    |> unique_constraint(:_clinic_id,
      name: :paystack_subaccounts_clinic_id_active_index,
      message: "already has an active Paystack subaccount"
    )
  end

  defp remove_nil_values(map) do
    map
    |> Enum.filter(fn {_unused, v} -> v != nil end)
    |> Map.new()
  end
end
