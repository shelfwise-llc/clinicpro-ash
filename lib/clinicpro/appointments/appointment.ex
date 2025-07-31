defmodule Clinicpro.Appointments.Appointment do
  @moduledoc """
  Multi-tenant appointment entity.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "appointments" do
    field :clinic_id, :string
    field :patient_id, :integer
    field :doctor_id, :integer
    field :appointment_date, :utc_datetime
    field :status, :string, default: "scheduled"
    field :notes, :string
    field :diagnosis, :string
    field :prescription, :map, default: %{}
    field :medical_details, :map, default: %{}

    timestamps()
  end

  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :clinic_id,
      :patient_id,
      :doctor_id,
      :appointment_date,
      :status,
      :notes,
      :diagnosis,
      :prescription,
      :medical_details
    ])
    |> validate_required([:clinic_id, :patient_id, :doctor_id, :appointment_date])
    |> validate_inclusion(:status, ["scheduled", "confirmed", "completed", "cancelled", "no_show"])
  end
end
