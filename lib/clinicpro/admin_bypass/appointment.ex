defmodule Clinicpro.AdminBypass.Appointment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "admin_bypass_appointments" do
    field :date, :date
    field :start_time, :time
    field :end_time, :time
    field :status, :string, default: "scheduled"
    field :notes, :string
    field :reason, :string
    field :diagnosis, :string
    field :prescription, :string

    belongs_to :doctor, Clinicpro.AdminBypass.Doctor
    belongs_to :patient, Clinicpro.AdminBypass.Patient

    timestamps()
  end

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:doctor_id, :patient_id, :date, :start_time, :end_time, :status, :notes, :reason, :diagnosis, :prescription])
    |> validate_required([:doctor_id, :patient_id, :date, :start_time, :end_time])
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:patient_id)
  end

  def list_appointments do
    Clinicpro.Repo.all(__MODULE__)
  end

  def list_appointments_with_associations do
    __MODULE__
    |> order_by([a], [desc: a.date, asc: a.start_time])
    |> Clinicpro.Repo.all()
    |> Clinicpro.Repo.preload([:doctor, :patient])
  end

  def list_recent_appointments(limit \\ 5) do
    __MODULE__
    |> order_by([a], [desc: a.inserted_at])
    |> limit(^limit)
    |> Clinicpro.Repo.all()
    |> Clinicpro.Repo.preload([:doctor, :patient])
  end

  def get_appointment!(id), do: Clinicpro.Repo.get!(__MODULE__, id)

  def get_appointment_with_associations!(id) do
    __MODULE__
    |> Clinicpro.Repo.get!(id)
    |> Clinicpro.Repo.preload([:doctor, :patient])
  end

  def create_appointment(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Clinicpro.Repo.insert()
  end

  def update_appointment(%__MODULE__{} = appointment, attrs) do
    appointment
    |> changeset(attrs)
    |> Clinicpro.Repo.update()
  end

  def delete_appointment(%__MODULE__{} = appointment) do
    Clinicpro.Repo.delete(appointment)
  end

  def change_appointment(%__MODULE__{} = appointment, attrs \\ %{}) do
    changeset(appointment, attrs)
  end
end
