defmodule Clinicpro.Doctor do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo
  alias Clinicpro.Appointment

  schema "doctors" do
    field :active, :boolean, default: true
    field :name, :string
    field :status, :string, default: "Active"
    field :email, :string
    field :specialty, :string
    field :phone, :string

    has_many :appointments, Appointment

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a doctor.
  """
  def changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [:name, :specialty, :email, :phone, :status, :active])
    |> validate_required([:name, :specialty, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
  end
  
  @doc """
  Gets a doctor by ID.
  """
  def get(id), do: Repo.get(__MODULE__, id)

  @doc """
  Gets a doctor by ID with preloaded appointments.
  """
  def get_with_appointments(id) do
    __MODULE__
    |> Repo.get(id)
    |> Repo.preload([:appointments])
  end

  @doc """
  Lists all doctors.
  """
  def list do
    Repo.all(__MODULE__)
  end

  @doc """
  Lists all active doctors.
  """
  def list_active do
    __MODULE__
    |> where(active: true)
    |> Repo.all()
  end

  @doc """
  Creates a new doctor.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a doctor.
  """
  def update(doctor, attrs) do
    doctor
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a doctor.
  """
  def delete(doctor) do
    Repo.delete(doctor)
  end
end
