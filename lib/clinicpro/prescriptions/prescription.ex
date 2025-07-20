defmodule Clinicpro.Prescriptions.Prescription do
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    attribute :medication_name, :string, allow_nil?: false
    attribute :dosage, :string, allow_nil?: false
    attribute :frequency, :string, allow_nil?: false
    attribute :duration, :string, allow_nil?: false
    attribute :instructions, :string, default: ""
    attribute :created_at, :utc_datetime_usec, default: &DateTime.utc_now/0
  end

  relationships do
    belongs_to :appointment, Clinicpro.Appointments.Appointment
    belongs_to :doctor, Clinicpro.Accounts.User
    belongs_to :patient, Clinicpro.Accounts.User
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create_for_appointment do
      argument :appointment_id, :uuid, allow_nil?: false
      argument :doctor_id, :uuid, allow_nil?: false
      argument :patient_id, :uuid, allow_nil?: false

      change set_attribute(:appointment_id, arg(:appointment_id))
      change set_attribute(:doctor_id, arg(:doctor_id))
      change set_attribute(:patient_id, arg(:patient_id))
    end

    read :list_by_patient do
      argument :patient_id, :uuid, allow_nil?: false
      filter expr(patient_id == ^arg(:patient_id))
    end

    read :list_by_doctor do
      argument :doctor_id, :uuid, allow_nil?: false
      filter expr(doctor_id == ^arg(:doctor_id))
    end

    read :list_by_appointment do
      argument :appointment_id, :uuid, allow_nil?: false
      filter expr(appointment_id == ^arg(:appointment_id))
    end
  end
end
