# Standalone script to set up the admin database without relying on full application compilation
# This bypasses AshAuthentication issues while allowing us to set up the admin panel database

# Define the modules we need without requiring the full application
defmodule AdminSetup do
  def run do
    # Start the Repo
    {:ok, _} = Application.ensure_all_started(:ecto)
    {:ok, _} = Clinicpro.Repo.start_link()

    IO.puts("Running migrations...")
    run_migrations()

    IO.puts("Seeding admin user...")
    run_admin_seeds()

    IO.puts("Seeding sample data...")
    run_sample_data_seeds()

    IO.puts("✅ Database setup completed!")
  end

  defp run_migrations do
    # Get all migration paths
    migrations_path = Path.join([:code.priv_dir(:clinicpro), "repo", "migrations"])
    
    # Run migrations
    Ecto.Migrator.run(Clinicpro.Repo, migrations_path, :up, all: true)
  end

  defp run_admin_seeds do
    # Load and evaluate admin seeds
    admin_seeds_path = Path.join([:code.priv_dir(:clinicpro), "repo", "seeds", "admin_seeds.exs"])
    if File.exists?(admin_seeds_path) do
      Code.eval_file(admin_seeds_path)
    else
      IO.puts("⚠️ Admin seeds file not found at #{admin_seeds_path}")
    end
  end

  defp run_sample_data_seeds do
    # Load and evaluate sample data seeds
    sample_data_seeds_path = Path.join([:code.priv_dir(:clinicpro), "repo", "seeds", "sample_data_seeds.exs"])
    if File.exists?(sample_data_seeds_path) do
      Code.eval_file(sample_data_seeds_path)
    else
      IO.puts("⚠️ Sample data seeds file not found at #{sample_data_seeds_path}")
    end
  end
end

# Run the setup
AdminSetup.run()
