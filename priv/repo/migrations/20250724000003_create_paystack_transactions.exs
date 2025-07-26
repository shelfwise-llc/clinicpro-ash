defmodule Clinicpro.Repo.Migrations.CreatePaystackTransactions do
  use Ecto.Migration

  def change do
    create table(:paystack_transactions) do
      add :clinic_id, :integer, null: false
      add :email, :string, null: false
      add :amount, :integer, null: false
      add :reference, :string, null: false
      add :paystack_reference, :string
      add :description, :string, null: false
      add :status, :string, default: "pending"
      add :authorization_url, :string
      add :access_code, :string
      add :payment_date, :utc_datetime
      add :channel, :string
      add :currency, :string
      add :fees, :integer
      add :gateway_response, :string
      add :metadata, :map, default: %{}

      timestamps()
    end

    # Add indexes
    create index(:paystack_transactions, [:clinic_id])
    create index(:paystack_transactions, [:status])
    create unique_index(:paystack_transactions, [:reference])

    create unique_index(:paystack_transactions, [:paystack_reference],
             where: "paystack_reference IS NOT NULL"
           )

    # Add a comment to the table
    execute "COMMENT ON TABLE paystack_transactions IS 'Stores Paystack payment transactions with clinic isolation'",
            ""
  end
end
