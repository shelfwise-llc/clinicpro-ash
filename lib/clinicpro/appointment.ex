defmodule Clinicpro.Appointment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo
  alias Clinicpro.Doctor
  alias Clinicpro.Patient

  schema "appointments" do
    field :status, :string, default: "Scheduled"
    field :type, :string
    field :date, :date
    field :start_time, :time
    field :end_time, :time
    field :notes, :string

    belongs_to :doctor, Doctor
    belongs_to :patient, Patient

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for an appointment.
  """
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:date, :start_time, :end_time, :status, :type, :notes, :doctor_id, :patient_id])
    |> validate_required([:date, :start_time, :end_time, :type, :doctor_id, :patient_id])
    |> validate_time_range()
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:patient_id)
  end

  @doc """
  Validates that end_time is after start_time.
  """
  defp validate_time_range(changeset) do
    case {get_field(changeset, :start_time), get_field(changeset, :end_time)} do
      {nil, _} -> changeset
      {_, nil} -> changeset
      {start_time, end_time} ->
        if Time.compare(end_time, start_time) == :gt do
          changeset
        else
          add_error(changeset, :end_time, "must be after start time")
        end
    end
  end

  @doc """
  Gets an appointment by ID.
  """
  def get(id), do: Repo.get(__MODULE__, id)

  @doc """
  Gets an appointment by ID with preloaded doctor and patient.
  """
  def get_with_associations(id) do
    __MODULE__
    |> Repo.get(id)
    |> Repo.preload([:doctor, :patient])
  end

  @doc """
  Lists all appointments.
  """
  def list do
    __MODULE__
    |> Repo.all()
    |> Repo.preload([:doctor, :patient])
  end

  @doc """
  Lists appointments for a specific date.
  """
  def list_by_date(date) do
    __MODULE__
    |> where(date: ^date)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient])
  end

  @doc """
  Lists appointments for a specific doctor.
  """
  def list_by_doctor(doctor_id) do
    __MODULE__
    |> where(doctor_id: ^doctor_id)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient])
  end

  @doc """
  Lists appointments for a specific patient.
  """
  def list_by_patient(patient_id) do
    __MODULE__
    |> where(patient_id: ^patient_id)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient])
  end

  @doc """
  Creates a new appointment.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an appointment.
  """
  def update(appointment, attrs) do
    appointment
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an appointment.
  """
  def delete(appointment) do
    Repo.delete(appointment)
  end
end
