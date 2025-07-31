defmodule Clinicpro.Appointments.AppointmentService do
  @moduledoc """
  SRP-compliant appointment management service.
  Handles appointment lifecycle per clinic.
  """

  alias Clinicpro.Appointments.Appointment
  alias Clinicpro.Repo
  import Ecto.Query

  @doc "Create appointment"
  def create_appointment(attrs, clinic_id) do
    %Appointment{}
    |> Appointment.changeset(Map.put(attrs, :clinic_id, clinic_id))
    |> Repo.insert()
  end

  @doc "Get appointments for clinic"
  def list_appointments(clinic_id) do
    Repo.all(from a in Appointment, where: a.clinic_id == ^clinic_id)
  end

  @doc "Get appointments for patient"
  def list_patient_appointments(patient_id, clinic_id) do
    Repo.all(from a in Appointment, 
             where: a.patient_id == ^patient_id and a.clinic_id == ^clinic_id)
  end

  @doc "Get appointments for doctor"
  def list_doctor_appointments(doctor_id, clinic_id) do
    Repo.all(from a in Appointment, 
             where: a.doctor_id == ^doctor_id and a.clinic_id == ^clinic_id)
  end

  @doc "Update appointment status"
  def update_appointment_status(appointment_id, status, clinic_id) do
    case Repo.get_by(Appointment, id: appointment_id, clinic_id: clinic_id) do
      nil -> {:error, :not_found}
      appointment ->
        appointment
        |> Appointment.changeset(%{status: status})
        |> Repo.update()
    end
  end
end
