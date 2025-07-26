defmodule Clinicpro.Appointment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  # # alias Clinicpro.Repo
  alias Clinicpro.Doctor
  alias Clinicpro.Patient
  alias Clinicpro.Clinic

  schema "appointments" do
    field :status, :string, default: "Scheduled"
    field :type, :string
    field :date, :date
    field :start_time, :time
    field :end_time, :time
    field :notes, :string
    field :meeting_link, :string
    # "onsite" or "virtual"
    field :appointment_type, :string, default: "onsite"

    belongs_to :doctor, Doctor
    belongs_to :patient, Patient
    belongs_to :clinic, Clinic

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for an _appointment.
  """
  def changeset(_appointment, attrs) do
    _appointment
    |> cast(attrs, [
      :date,
      :start_time,
      :end_time,
      :status,
      :type,
      :notes,
      :doctor_id,
      :patient_id,
      :_clinic_id,
      :meeting_link,
      :appointment_type
    ])
    |> validate_required([
      :date,
      :start_time,
      :end_time,
      :type,
      :doctor_id,
      :patient_id,
      :appointment_type
    ])
    |> validate_time_range()
    |> foreign_key_constraint(:doctor_id)
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:_clinic_id)
  end

  @doc """
  Returns a changeset for tracking _appointment changes.
  """
  def change(%__MODULE__{} = _appointment, attrs \\ %{}) do
    changeset(_appointment, attrs)
  end

  @doc """
  Validates that end_time is after start_time.
  """
  defp validate_time_range(changeset) do
    case {get_field(changeset, :start_time), get_field(changeset, :end_time)} do
      {nil, _unused} ->
        changeset

      {_unused, nil} ->
        changeset

      {start_time, end_time} ->
        if Time.compare(end_time, start_time) == :gt do
          changeset
        else
          add_error(changeset, :end_time, "must be after start time")
        end
    end
  end

  @doc """
  Gets an _appointment by ID.
  """
  def get(id), do: Repo.get(__MODULE__, id)

  @doc """
  Gets an _appointment by ID with preloaded doctor and patient.
  """
  def get_with_associations(id) do
    __MODULE__
    |> Repo.get(id)
    |> Repo.preload([:doctor, :patient, :clinic])
  end

  @doc """
  Lists all appointments.
  """
  def list do
    __MODULE__
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :clinic])
  end

  @doc """
  Lists appointments with optional filtering.

  ## Options

  * `:limit` - Limits the number of results
  * `:status` - Filter by _appointment status
  * `:date` - Filter by specific date
  * `:doctor_id` - Filter by doctor
  * `:patient_id` - Filter by patient
  * `:type` - Filter by _appointment type
  """
  def list(_opts) do
    __MODULE__
    |> filter_by_status(_opts)
    |> filter_by_date(_opts)
    |> filter_by_doctor_id(_opts)
    |> filter_by_patient_id(_opts)
    |> filter_by_type(_opts)
    |> limit_query(_opts)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :clinic])
  end

  # Private filter functions
  defp filter_by_status(query, %{status: status}) when is_binary(status) and status != "",
    do: where(query, [a], a.status == ^status)

  defp filter_by_status(query, _unused), do: query

  defp filter_by_date(query, %{date: date}) when not is_nil(date),
    do: where(query, [a], a.date == ^date)

  defp filter_by_date(query, _unused), do: query

  defp filter_by_doctor_id(query, %{doctor_id: doctor_id}) when not is_nil(doctor_id),
    do: where(query, [a], a.doctor_id == ^doctor_id)

  defp filter_by_doctor_id(query, _unused), do: query

  defp filter_by_patient_id(query, %{patient_id: patient_id}) when not is_nil(patient_id),
    do: where(query, [a], a.patient_id == ^patient_id)

  defp filter_by_patient_id(query, _unused), do: query

  defp filter_by_type(query, %{type: type}) when is_binary(type) and type != "",
    do: where(query, [a], a.type == ^type)

  defp filter_by_type(query, _unused), do: query

  defp limit_query(query, %{limit: limit}) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp limit_query(query, _unused), do: query

  @doc """
  Lists appointments for a specific date.
  """
  def list_by_date(date) do
    __MODULE__
    |> where(date: ^date)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :clinic])
  end

  @doc """
  Lists appointments for a specific doctor.
  """
  def list_by_doctor(doctor_id) do
    __MODULE__
    |> where(doctor_id: ^doctor_id)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :clinic])
  end

  @doc """
  Lists appointments for a specific patient.
  """
  def list_by_patient(patient_id) do
    __MODULE__
    |> where(patient_id: ^patient_id)
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :clinic])
  end

  @doc """
  Lists all appointments with doctor and patient associations preloaded.
  """
  def list_with_associations do
    __MODULE__
    |> Repo.all()
    |> Repo.preload([:doctor, :patient, :clinic])
  end

  @doc """
  Creates a new _appointment.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an _appointment.
  """
  def update(_appointment, attrs) do
    _appointment
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an _appointment.
  """
  def delete(_appointment) do
    Repo.delete(_appointment)
  end
end
