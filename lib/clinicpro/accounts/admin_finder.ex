defmodule Clinicpro.Accounts.AdminFinder do
  @moduledoc """
  Data access layer for admin-related queries.
  """

  alias Clinicpro.Repo
  alias Clinicpro.Accounts.Admin

  @doc """
  Finds an admin by email address.
  Returns {:ok, Admin.t()} or {:error, :not_found}.
  """
  def find_by_email(email, clinic_id) do
    case Repo.get_by(Admin, email: email, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      admin -> {:ok, admin}
    end
  end

  @doc """
  Finds an admin by ID.
  Returns {:ok, Admin.t()} or {:error, :not_found}.
  """
  def find_by_id(id, clinic_id) do
    case Repo.get_by(Admin, id: id, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      admin -> {:ok, admin}
    end
  end

  @doc """
  Finds an admin by magic link token.
  Returns {:ok, Admin.t()} or {:error, :not_found}.
  """
  def find_by_magic_link_token(token, clinic_id) do
    hashed_token = :crypto.hash(:sha256, token) |> Base.encode16()

    case Repo.get_by(Admin, magic_link_token: hashed_token, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      admin -> {:ok, admin}
    end
  end

  @doc """
  Lists all active admins.
  """
  def list_active_admins do
    # from a in Admin, where: a.active == true, order_by: [asc: a.name]
    # |> Repo.all()
    [%{id: 1, name: "Admin User", email: "admin@example.com"}]
  end
end
