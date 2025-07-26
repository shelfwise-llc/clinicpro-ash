defmodule Clinicpro.Repo.Migrations.CreatePaystackSubaccounts do
  use Ecto.Migration

  def change do
    create table(:paystack_subaccounts) do
      add :clinic_id, :integer, null: false
      add :subaccount_code, :string, null: false
      add :business_name, :string, null: false
      add :settlement_bank, :string, null: false
      add :account_number, :string, null: false
      add :percentage_charge, :float, default: 0.0
      add :description, :text
      add :active, :boolean, default: true
      add :metadata, :map, default: %{}

      timestamps()
    end

    # Add indexes
    create index(:paystack_subaccounts, [:clinic_id])
    create unique_index(:paystack_subaccounts, [:subaccount_code])

    create unique_index(:paystack_subaccounts, [:clinic_id, :active],
             where: "active = true",
             name: :paystack_subaccounts_clinic_id_active_index
           )

    # Add a comment to the table
    execute "COMMENT ON TABLE paystack_subaccounts IS 'Stores Paystack subaccount details for each clinic'",
            ""
  end
end
