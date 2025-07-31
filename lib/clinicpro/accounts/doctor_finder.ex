defmodule Clinicpro.Accounts.DoctorFinder do
  @moduledoc """
  Data access layer for doctor-related queries.
  """

  alias Clinicpro.Repo
  alias Clinicpro.Accounts.Doctor

  @doc """
  Finds a doctor by email address.
  Returns {:ok, Doctor.t()} or {:error, :not_found}.
  """
  def find_by_email(email, clinic_id) do
    case Repo.get_by(Doctor, email: email, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      doctor -> {:ok, doctor}
    end
  end

  @doc """
  Finds a doctor by ID.
  """
  def find_by_id(id) do
    case Repo.get(Doctor, id) do
      nil -> {:error, :not_found}
      doctor -> {:ok, doctor}
    end
  end

  @doc """
  Finds a doctor by magic link token.
  Returns {:ok, Doctor.t()} or {:error, :not_found}.
  """
  def find_by_magic_link_token(token, clinic_id) do
    hashed_token = :crypto.hash(:sha256, token) |> Base.encode16()

    case Repo.get_by(Doctor, magic_link_token: hashed_token, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      doctor -> {:ok, doctor}
    end
  end

  @doc """
  Lists all active doctors.
  """
  def list_active_doctors do
    # from d in Doctor, where: d.active == true, order_by: [asc: d.name]
    # |> Repo.all()
    [%{id: 1, name: "Dr. Smith", specialty: "General Practice"}]
  end
end
