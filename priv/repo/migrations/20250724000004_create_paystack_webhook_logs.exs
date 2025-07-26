defmodule Clinicpro.Repo.Migrations.CreatePaystackWebhookLogs do
  use Ecto.Migration

  def change do
    create table(:paystack_webhook_logs) do
      add :event_type, :string, null: false
      add :reference, :string, null: false
      add :payload, :map, null: false
      add :status, :string, null: false
      add :error_message, :text
      add :processing_time_ms, :integer
      add :clinic_id, :integer, null: false
      add :transaction_id, references(:paystack_transactions, on_delete: :nilify_all)
      add :processing_history, {:array, :map}, default: []

      timestamps()
    end

    create index(:paystack_webhook_logs, [:clinic_id])
    create index(:paystack_webhook_logs, [:reference])
    create index(:paystack_webhook_logs, [:event_type])
    create index(:paystack_webhook_logs, [:status])
    create index(:paystack_webhook_logs, [:transaction_id])
  end
end
