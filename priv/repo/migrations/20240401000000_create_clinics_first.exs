defmodule Clinicpro.Repo.Migrations.CreateClinicsFirst do
  use Ecto.Migration

  def up do
    # First, check if the clinics table already exists
    table_exists = table_exists?(:clinics)
    
    unless table_exists do
      # Create the clinics table with the same structure as the existing migration
      create table(:clinics, primary_key: false) do
        add :id, :binary_id, primary_key: true
        timestamps(type: :utc_datetime)
      end
      
      # Mark the original clinics migration as completed
      execute """
        INSERT INTO schema_migrations (version, inserted_at)
        VALUES ('20250720185125', now())
        ON CONFLICT (version) DO NOTHING
      """
    end
  end

  def down do
    # This is not reversible since we're fixing migration order
  end
  
  # Helper function to check if a table exists
  defp table_exists?(table_name) do
    query = """
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public'
        AND table_name = '#{table_name}'
      );
    """
    
    case Ecto.Adapters.SQL.query(Clinicpro.Repo, query, []) do
      {:ok, %{rows: [[true]]}} -> true
      _ -> false
    end
  end
end
