defmodule Clinicpro.Repo.Migrations.AddVirtualMeetingFieldsToAdminBypassAppointments do
  use Ecto.Migration

  def change do
    alter table(:admin_bypass_appointments) do
      add :meeting_link, :string
      add :appointment_type, :string, default: "onsite"
    end

    create index(:admin_bypass_appointments, [:appointment_type])
  end
end
