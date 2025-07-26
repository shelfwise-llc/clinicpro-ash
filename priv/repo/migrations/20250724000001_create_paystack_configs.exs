defmodule Clinicpro.Repo.Migrations.CreatePaystackConfigs do
  use Ecto.Migration

  def change do
    create table(:paystack_configs) do
      add :clinic_id, :integer, null: false
      add :secret_key, :string, null: false
      add :public_key, :string, null: false
      add :environment, :string, default: "test"
      add :base_url, :string, default: "https://api.paystack.co"
      add :webhook_url, :string
      add :active, :boolean, default: true

      timestamps()
    end

    # Add indexes
    create index(:paystack_configs, [:clinic_id])

    create unique_index(:paystack_configs, [:clinic_id, :active],
             where: "active = true",
             name: :paystack_configs_clinic_id_active_index
           )

    # Add a comment to the table
    execute "COMMENT ON TABLE paystack_configs IS 'Stores Paystack configuration settings for each clinic'",
            ""
  end
end
