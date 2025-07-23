defmodule Clinicpro.Repo.Migrations.AddVirtualMeetingFieldsToAppointments do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add :meeting_link, :string
      add :appointment_type, :string, default: "onsite"
      add :clinic_id, references(:clinics, on_delete: :nilify_all), null: true
    end

    # Add an index for faster lookups by clinic
    create index(:appointments, [:clinic_id])
  end
end
