defmodule Clinicpro.Paystack.Subaccount do
  @moduledoc """
  Module for managing Paystack subaccounts for clinics.

  This module provides functions for creating, updating, retrieving, and managing
  Paystack subaccounts for clinics, following the multi-tenant architecture pattern.

  Each clinic can have multiple subaccounts, but only one can be active at a time.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo
  alias Clinicpro.Paystack.API
  alias __MODULE__

  schema "paystack_subaccounts" do
    field :clinic_id, :integer
    field :business_name, :string
    field :settlement_bank, :string
    field :account_number, :string
    field :percentage_charge, :decimal
    field :description, :string
    field :subaccount_code, :string
    field :active, :boolean, default: false

    timestamps()
  end

  @doc """
  Creates a changeset for a Paystack subaccount.
  """
  def changeset(subaccount, attrs) do
    subaccount
    |> cast(attrs, [
      :clinic_id,
      :business_name,
      :settlement_bank,
      :account_number,
      :percentage_charge,
      :description,
      :subaccount_code,
      :active
    ])
    |> validate_required([
      :clinic_id,
      :business_name,
      :settlement_bank,
      :account_number,
      :percentage_charge
    ])
    |> validate_number(:percentage_charge,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> unique_constraint([:clinic_id, :subaccount_code])
    |> maybe_deactivate_other_subaccounts()
  end

  @doc """
  Creates a new Paystack subaccount for a clinic.

  ## Parameters

  * `attrs` - Attributes for the new subaccount

  ## Returns

  * `{:ok, subaccount}` - The created subaccount
  * `{:error, changeset}` - Error changeset

  """
  def create(attrs) do
    # First create the subaccount on Paystack
    with {:ok, paystack_response} <-
           API.create_subaccount(
             attrs["business_name"],
             attrs["settlement_bank"],
             attrs["account_number"],
             attrs["percentage_charge"],
             attrs["description"],
             attrs["clinic_id"],
             attrs["active"]
           ) do
      # Then save to our database with the subaccount code from Paystack
      attrs = Map.put(attrs, "subaccount_code", paystack_response["data"]["subaccount_code"])

      %Subaccount{}
      |> changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Updates an existing Paystack subaccount.

  ## Parameters

  * `subaccount` - The subaccount to update
  * `attrs` - Attributes to update

  ## Returns

  * `{:ok, subaccount}` - The updated subaccount
  * `{:error, changeset}` - Error changeset

  """
  def update(subaccount, attrs) do
    # Update the subaccount on Paystack if subaccount_code is present
    if subaccount.subaccount_code do
      # Call Paystack API to update the subaccount
      with {:ok, _paystack_response} <-
             API.update_subaccount(
               subaccount.subaccount_code,
               attrs["business_name"] || subaccount.business_name,
               attrs["settlement_bank"] || subaccount.settlement_bank,
               attrs["account_number"] || subaccount.account_number,
               attrs["percentage_charge"] || subaccount.percentage_charge,
               attrs["description"] || subaccount.description,
               attrs["active"] || subaccount.active
             ) do
        # Then update our local record
        subaccount
        |> changeset(attrs)
        |> Repo.update()
      else
        {:error, reason} -> {:error, reason}
      end
    else
      # If no subaccount_code, just update our local record
      subaccount
      |> changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Gets a Paystack subaccount by ID.

  ## Parameters

  * `id` - ID of the subaccount

  ## Returns

  * `{:ok, subaccount}` - The subaccount
  * `{:error, :not_found}` - Subaccount not found

  """
  def get(id) do
    case Repo.get(Subaccount, id) do
      nil -> {:error, :not_found}
      subaccount -> {:ok, subaccount}
    end
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
  def get_by_id_and_clinic(id, clinic_id) do
    case Repo.get_by(Subaccount, id: id, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      subaccount -> {:ok, subaccount}
    end
  end

  @doc """
  Gets a Paystack subaccount by subaccount code.

  ## Parameters

  * `subaccount_code` - Paystack subaccount code
  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, subaccount}` - The subaccount
  * `{:error, :not_found}` - Subaccount not found

  """
  def get_by_subaccount_code(subaccount_code, clinic_id) do
    case Repo.get_by(Subaccount, subaccount_code: subaccount_code, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      subaccount -> {:ok, subaccount}
    end
  end

  @doc """
  Gets the active Paystack subaccount for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * `{:ok, subaccount}` - The active subaccount
  * `{:error, :not_found}` - No active subaccount found

  """
  def getactive(clinic_id) do
    case Repo.one(from s in Subaccount, where: s.clinic_id == ^clinic_id and s.active == true) do
      nil -> {:error, :not_found}
      subaccount -> {:ok, subaccount}
    end
  end

  @doc """
  Lists all Paystack subaccounts for a clinic.

  ## Parameters

  * `clinic_id` - ID of the clinic

  ## Returns

  * List of subaccounts

  """
  def list_by_clinic(clinic_id) do
    Repo.all(
      from s in Subaccount,
        where: s.clinic_id == ^clinic_id,
        order_by: [desc: s.active, desc: s.inserted_at]
    )
  end

  @doc """
  Activates a Paystack subaccount and deactivates all others for the clinic.

  ## Parameters

  * `id` - ID of the subaccount to activate

  ## Returns

  * `{:ok, subaccount}` - The activated subaccount
  * `{:error, reason}` - Error reason

  """
  def activate(id) do
    Repo.transaction(fn ->
      with {:ok, subaccount} <- get(id),
           :ok <- deactivate_all_for_clinic(subaccount.clinic_id),
           {:ok, updated_subaccount} <- Repo.update(changeset(subaccount, %{isactive: true})) do
        updated_subaccount
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Deactivates a Paystack subaccount.

  ## Parameters

  * `id` - ID of the subaccount to deactivate

  ## Returns

  * `{:ok, subaccount}` - The deactivated subaccount
  * `{:error, reason}` - Error reason

  """
  def deactivate(id) do
    with {:ok, subaccount} <- get(id) do
      Repo.update(changeset(subaccount, %{isactive: false}))
    end
  end

  @doc """
  Deletes a Paystack subaccount.

  ## Parameters

  * `id` - ID of the subaccount to delete

  ## Returns

  * `{:ok, subaccount}` - The deleted subaccount
  * `{:error, reason}` - Error reason

  """
  def delete(id) do
    with {:ok, subaccount} <- get(id) do
      Repo.delete(subaccount)
    end
  end

  # Private functions

  # Deactivate all other subaccounts for the clinic if this one is being activated
  defp maybe_deactivate_other_subaccounts(changeset) do
    case get_change(changeset, :isactive) do
      true ->
        clinic_id = get_field(changeset, :clinic_id)
        deactivate_all_for_clinic(clinic_id)
        changeset

      _unused ->
        changeset
    end
  end

  # Deactivate all subaccounts for a clinic
  defp deactivate_all_for_clinic(clinic_id) do
    from(s in Subaccount, where: s.clinic_id == ^clinic_id)
    |> Repo.update_all(set: [isactive: false])

    :ok
  end
end
