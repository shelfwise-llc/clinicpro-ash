defmodule Clinicpro.Repo.Migrations.CreateMpesaTables do
  use Ecto.Migration

  def change do
    # M-Pesa configurations per clinic
    create table(:mpesa_configs) do
      add :clinic_id, references(:admin_bypass_doctors, on_delete: :delete_all), null: false
      add :consumer_key, :string, null: false
      add :consumer_secret, :string, null: false
      add :passkey, :string, null: false
      add :shortcode, :string, null: false
      add :c2b_shortcode, :string
      add :environment, :string, default: "sandbox"
      add :stk_callback_url, :string
      add :c2b_validation_url, :string
      add :c2b_confirmation_url, :string
      add :active, :boolean, default: true

      timestamps()
    end

    create index(:mpesa_configs, [:clinic_id])
    create unique_index(:mpesa_configs, [:clinic_id, :active], where: "active = true")

    # M-Pesa transactions
    create table(:mpesa_transactions) do
      add :clinic_id, references(:admin_bypass_doctors, on_delete: :nilify_all)
      add :checkout_request_id, :string
      add :merchant_request_id, :string
      add :reference, :string, null: false
      add :phone, :string, null: false
      add :amount, :decimal, null: false
      add :description, :string
      add :status, :string, default: "pending", null: false
      add :result_code, :string
      add :result_desc, :string
      add :transaction_date, :utc_datetime
      add :mpesa_receipt_number, :string
      add :type, :string, null: false # "stk_push" or "c2b"
      add :raw_request, :map
      add :raw_response, :map

      timestamps()
    end

    create index(:mpesa_transactions, [:clinic_id])
    create index(:mpesa_transactions, [:checkout_request_id])
    create index(:mpesa_transactions, [:reference])
    create index(:mpesa_transactions, [:status])
    create index(:mpesa_transactions, [:mpesa_receipt_number])
  end
end
