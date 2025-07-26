defmodule Clinicpro.Mocks.Appointments do
  @moduledoc """
  Mock implementation of the Appointments API for tests.
  This completely bypasses the Ash resources to avoid compilation issues.
  """

  # Define structs locally to avoid compilation order issues
  defmodule MockAppointment do
    defstruct [
      :id,
      :patient_name,
      :date,
      :time,
      :reason,
      :status,
      :clinic_id,
      :doctor_id,
      :patient_id,
      :type,
      :medical_details,
      :diagnosis
    ]
  end

  defmodule MockUser do
    defstruct [:id, :email, :role, :doctor, :patient, :admin]
  end

  defmodule MockDoctor do
    defstruct [:id, :first_name, :last_name, :specialty, :clinic_id]
  end

  defmodule MockPatient do
    defstruct [:id, :first_name, :last_name, :date_of_birth]
  end

  # Appointment management functions
  def get_appointment(id) do
    {:ok,
     %MockAppointment{
       id: id,
       doctor_id: "doctor-123",
       patient_id: "patient-456",
       date: "2025-07-25",
       time: "10:00 AM",
       type: "Consultation",
       status: "scheduled"
     }}
  end

  def list_appointments(filters) do
    doctor_id = filters[:doctor_id]
    patient_id = filters[:patient_id]

    appointments = [
      %MockAppointment{
        id: "appt-1",
        doctor_id: doctor_id || "doctor-123",
        patient_id: patient_id || "patient-456",
        date: "2025-07-25",
        time: "10:00 AM",
        type: "Consultation",
        status: "scheduled"
      },
      %MockAppointment{
        id: "appt-2",
        doctor_id: doctor_id || "doctor-123",
        patient_id: patient_id || "patient-789",
        date: "2025-07-26",
        time: "11:00 AM",
        type: "Follow-up",
        status: "scheduled"
      }
    ]

    {:ok, appointments}
  end

  def create_appointment(attrs) do
    {:ok,
     %MockAppointment{
       id: Ecto.UUID.generate(),
       doctor_id: attrs[:doctor_id],
       patient_id: attrs[:patient_id],
       date: attrs[:date],
       time: attrs[:time],
       type: attrs[:type],
       status: "scheduled"
     }}
  end

  def update_appointment(id, attrs) do
    {:ok,
     %MockAppointment{
       id: id,
       doctor_id: attrs[:doctor_id] || "doctor-123",
       patient_id: attrs[:patient_id] || "patient-456",
       date: attrs[:date] || "2025-07-25",
       time: attrs[:time] || "10:00 AM",
       type: attrs[:type] || "Consultation",
       status: attrs[:status] || "scheduled"
     }}
  end

  def delete_appointment(id) do
    {:ok, %MockAppointment{id: id, status: "deleted"}}
  end

  # Medical details and diagnosis functions
  def save_medical_details(appointment_id, medical_details) do
    {:ok,
     %MockAppointment{
       id: appointment_id,
       status: "medical_details_recorded",
       medical_details: medical_details
     }}
  end

  def save_diagnosis(appointment_id, diagnosis) do
    {:ok,
     %MockAppointment{
       id: appointment_id,
       status: "diagnosis_recorded",
       diagnosis: diagnosis
     }}
  end

  def complete_appointment(appointment_id) do
    {:ok,
     %MockAppointment{
       id: appointment_id,
       status: "completed"
     }}
  end
end
