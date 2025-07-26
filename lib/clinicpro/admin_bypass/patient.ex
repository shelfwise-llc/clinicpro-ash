defmodule Clinicpro.AdminBypass.Patient do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "admin_bypass_patients" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :date_of_birth, :date
    field :gender, :string
    field :medical_history, :string
    field :active, :boolean, default: true

    has_many :appointments, Clinicpro.AdminBypass.Appointment

    timestamps()
  end

  @doc false
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :first_name,
      :last_name,
      :email,
      :phone,
      :date_of_birth,
      :gender,
      :medical_history,
      :active
    ])
    |> validate_required([:first_name, :last_name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
  end

  def list_patients do
    __MODULE__
    |> order_by([p], asc: p.last_name)
    |> Clinicpro.Repo.all()
  end

  def list_recent_patients(limit \\ 3) do
    __MODULE__
    |> order_by([p], desc: p.inserted_at)
    |> limit(^limit)
    |> Clinicpro.Repo.all()
  end

  def get_patient!(id), do: Clinicpro.Repo.get!(__MODULE__, id)

  def get_patient(id), do: Clinicpro.Repo.get(__MODULE__, id)

  def create_patient(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Clinicpro.Repo.insert()
  end

  def update_patient(%__MODULE__{} = patient, attrs) do
    patient
    |> changeset(attrs)
    |> Clinicpro.Repo.update()
  end

  def delete_patient(%__MODULE__{} = patient) do
    Clinicpro.Repo.delete(patient)
  end

  def change_patient(%__MODULE__{} = patient, attrs \\ %{}) do
    changeset(patient, attrs)
  end
end
