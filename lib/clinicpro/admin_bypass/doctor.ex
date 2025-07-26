defmodule Clinicpro.AdminBypass.Doctor do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "admin_bypass_doctors" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :specialty, :string
    field :bio, :string
    field :active, :boolean, default: true
    field :years_of_experience, :integer
    field :consultation_fee, :decimal

    has_many :appointments, Clinicpro.AdminBypass.Appointment

    timestamps()
  end

  @doc false
  def changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [
      :first_name,
      :last_name,
      :email,
      :phone,
      :specialty,
      :bio,
      :active,
      :years_of_experience,
      :consultation_fee
    ])
    |> validate_required([:first_name, :last_name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
  end

  def list_doctors do
    __MODULE__
    |> order_by([d], asc: d.last_name)
    |> Clinicpro.Repo.all()
  end

  def list_recent_doctors(limit \\ 2) do
    __MODULE__
    |> order_by([d], desc: d.inserted_at)
    |> limit(^limit)
    |> Clinicpro.Repo.all()
  end

  def get_doctor!(id), do: Clinicpro.Repo.get!(__MODULE__, id)

  def get_doctor(id), do: Clinicpro.Repo.get(__MODULE__, id)

  def create_doctor(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Clinicpro.Repo.insert()
  end

  def update_doctor(%__MODULE__{} = doctor, attrs) do
    doctor
    |> changeset(attrs)
    |> Clinicpro.Repo.update()
  end

  def delete_doctor(%__MODULE__{} = doctor) do
    Clinicpro.Repo.delete(doctor)
  end

  def change_doctor(%__MODULE__{} = doctor, attrs \\ %{}) do
    changeset(doctor, attrs)
  end
end
