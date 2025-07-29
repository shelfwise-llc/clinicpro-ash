defmodule Clinicpro.Repo.Migrations.FixAdminBypassInvoiceClinicIdReference do
  use Ecto.Migration

  def change do
    # Drop the existing foreign key constraint
    drop constraint(:admin_bypass_invoices, "admin_bypass_invoices_clinic_id_fkey")

    # Drop the existing column
    alter table(:admin_bypass_invoices) do
      remove :clinic_id
    end

    # Add the column back with the correct reference to clinics table
    alter table(:admin_bypass_invoices) do
      add :clinic_id, references(:clinics, on_delete: :restrict, type: :binary_id), null: false
    end
  end
end
