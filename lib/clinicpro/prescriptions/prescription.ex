defmodule Clinicpro.Prescriptions.Prescription do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("prescriptions")
    repo(Clinicpro.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:medication_name, :string, allow_nil?: false)
    attribute(:dosage, :string, allow_nil?: false)
    attribute(:frequency, :string, allow_nil?: false)
    attribute(:duration, :string, allow_nil?: false)
    attribute(:instructions, :string, default: "")
    attribute(:created_at, :utc_datetime_usec, default: &DateTime.utc_now/0)

    # Additional fields for medication details
    attribute(:medication_code, :string)
    # e.g., tablet, syrup, injection
    attribute(:medication_form, :string)
    # e.g., 500mg, 250ml
    attribute(:medication_strength, :string)
    attribute(:refills, :integer, default: 0)
    attribute(:is_controlled_substance, :boolean, default: false)
    attribute(:clinic_id, :uuid, allow_nil?: false)
  end

  relationships do
    belongs_to :appointment, Clinicpro.Appointments.Appointment
    belongs_to :doctor, Clinicpro.Accounts.User
    belongs_to :patient, Clinicpro.Accounts.User
    belongs_to :clinic, Clinicpro.Clinics.Clinic
  end

  actions do
    defaults([:create, :read, :update, :destroy])

    create :create_for_appointment do
      argument(:appointment_id, :uuid, allow_nil?: false)
      argument(:doctor_id, :uuid, allow_nil?: false)
      argument(:patient_id, :uuid, allow_nil?: false)
      argument(:clinic_id, :uuid, allow_nil?: false)

      change(set_attribute(:appointment_id, arg(:appointment_id)))
      change(set_attribute(:doctor_id, arg(:doctor_id)))
      change(set_attribute(:patient_id, arg(:patient_id)))
      change(set_attribute(:clinic_id, arg(:clinic_id)))
    end

    read :list_by_patient do
      argument(:patient_id, :uuid, allow_nil?: false)
      filter(expr(patient_id == ^arg(:patient_id)))
    end

    read :list_by_doctor do
      argument(:doctor_id, :uuid, allow_nil?: false)
      filter(expr(doctor_id == ^arg(:doctor_id)))
    end

    read :list_by_appointment do
      argument(:appointment_id, :uuid, allow_nil?: false)
      filter(expr(appointment_id == ^arg(:appointment_id)))
    end

    read :list_by_clinic do
      argument(:clinic_id, :uuid, allow_nil?: false)
      filter(expr(clinic_id == ^arg(:clinic_id)))
    end
  end

  # Multi-tenant isolation is handled through Ecto queries
  # Each query filters by clinic_id to ensure proper data isolation
end
