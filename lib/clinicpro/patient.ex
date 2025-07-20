defmodule Clinicpro.Patient do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo
  alias Clinicpro.Appointment

  schema "patients" do
    field :active, :boolean, default: true
    field :status, :string, default: "Active"
    field :address, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :date_of_birth, :date
    field :gender, :string
    field :medical_history, :string
    field :insurance_provider, :string
    field :insurance_number, :string

    has_many :appointments, Appointment

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a patient.
  """
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :date_of_birth, :gender, :address, :medical_history, :insurance_provider, :insurance_number, :status, :active])
    |> validate_required([:first_name, :last_name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
  end

  @doc """
  Gets a patient's full name.
  """
  def full_name(patient) do
    "#{patient.first_name} #{patient.last_name}"
  end

  @doc """
  Gets a patient by ID.
  """
  def get(id), do: Repo.get(__MODULE__, id)

  @doc """
  Gets a patient by ID with preloaded appointments.
  """
  def get_with_appointments(id) do
    __MODULE__
    |> Repo.get(id)
    |> Repo.preload([:appointments])
  end

  @doc """
  Lists all patients.
  """
  def list do
    Repo.all(__MODULE__)
  end

  @doc """
  Lists all active patients.
  """
  def list_active do
    __MODULE__
    |> where(active: true)
    |> Repo.all()
  end

  @doc """
  Creates a new patient.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient.
  """
  def update(patient, attrs) do
    patient
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a patient.
  """
  def delete(patient) do
    Repo.delete(patient)
  end
end
