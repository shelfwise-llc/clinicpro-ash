defmodule Clinicpro.Accounts.PatientFinder do
  @moduledoc """
  Data access layer for patient-related queries.
  """

  alias Clinicpro.Repo
  alias Clinicpro.Accounts.Patient

  @doc """
  Finds a patient by email address.
  Returns {:ok, Patient.t()} or {:error, :not_found}.
  """
  def find_by_email(email, clinic_id) do
    case Repo.get_by(Patient, email: email, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      patient -> {:ok, patient}
    end
  end

  @doc """
  Finds a patient by ID.
  Returns {:ok, Patient.t()} or {:error, :not_found}.
  """
  def find_by_id(id, clinic_id) do
    case Repo.get_by(Patient, id: id, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      patient -> {:ok, patient}
    end
  end

  @doc """
  Finds a patient by magic link token.
  """
  def find_by_magic_link_token(token, clinic_id) do
    # This would query the tokens table to find patient by token
    # Stub implementation for now
    hashed_token = :crypto.hash(:sha256, token) |> Base.encode16()

    {:ok, %{id: 1, email: "patient@example.com", name: "John Patient", clinic_id: clinic_id}}
  end

  @doc """
  Lists all active patients.
  """
  def list_active_patients do
    # from p in Patient, where: p.active == true, order_by: [asc: p.name]
    # |> Repo.all()
    [%{id: 1, name: "John Patient", email: "patient@example.com"}]
  end
end
