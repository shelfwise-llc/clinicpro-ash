defmodule Clinicpro.Repo.Migrations.CreateMPesaTables do
  use Ecto.Migration

  def change do
    # Create M-Pesa configurations table
    create table(:mpesa_configs) do
      add :clinic_id, :integer, null: false
      add :consumer_key, :string, null: false
      add :consumer_secret, :string, null: false
      add :passkey, :string, null: false
      add :shortcode, :string, null: false
      add :environment, :string, null: false, default: "sandbox"
      add :base_url, :string, null: false
      add :callback_url, :string
      add :validation_url, :string
      add :confirmation_url, :string
      add :active, :boolean, default: true

      timestamps()
    end

    # Create indexes for mpesa_configs
    create index(:mpesa_configs, [:clinic_id])
    create index(:mpesa_configs, [:shortcode])
    create unique_index(:mpesa_configs, [:shortcode, :environment])

    # Create M-Pesa transactions table
    create table(:mpesa_transactions) do
      add :clinic_id, :integer, null: false
      add :invoice_id, :string, null: false
      add :patient_id, :string, null: false
      add :phone_number, :string, null: false
      add :amount, :float, null: false
      add :status, :string, null: false, default: "pending"
      add :reference, :string
      add :checkout_request_id, :string
      add :merchant_request_id, :string
      add :transaction_id, :string
      add :transaction_date, :naive_datetime
      add :result_code, :string
      add :result_desc, :string

      timestamps()
    end

    # Create indexes for mpesa_transactions
    create index(:mpesa_transactions, [:clinic_id])
    create index(:mpesa_transactions, [:invoice_id])
    create index(:mpesa_transactions, [:patient_id])
    create index(:mpesa_transactions, [:checkout_request_id])
    create index(:mpesa_transactions, [:merchant_request_id])
    create index(:mpesa_transactions, [:transaction_id])
    create index(:mpesa_transactions, [:reference])
    create index(:mpesa_transactions, [:status])
  end
end
