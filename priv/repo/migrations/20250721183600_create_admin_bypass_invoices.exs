defmodule Clinicpro.Repo.Migrations.CreateAdminBypassInvoices do
  use Ecto.Migration

  def change do
    create table(:admin_bypass_invoices) do
      add :invoice_number, :string, null: false
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :status, :string, null: false, default: "pending"
      add :due_date, :date, null: false
      add :description, :string
      add :payment_reference, :string
      add :notes, :text

      # Invoice items as JSON
      add :items, :map, default: "[]"

      # Foreign keys
      add :patient_id, references(:admin_bypass_patients, on_delete: :restrict, type: :uuid),
        null: false

      add :clinic_id, references(:admin_bypass_doctors, on_delete: :restrict, type: :uuid),
        null: false

      add :appointment_id,
          references(:admin_bypass_appointments, on_delete: :nilify_all, type: :uuid)

      timestamps()
    end

    # Indexes
    create unique_index(:admin_bypass_invoices, [:invoice_number])
    create index(:admin_bypass_invoices, [:patient_id])
    create index(:admin_bypass_invoices, [:clinic_id])
    create index(:admin_bypass_invoices, [:appointment_id])
    create index(:admin_bypass_invoices, [:status])
    create index(:admin_bypass_invoices, [:payment_reference])
  end
end
