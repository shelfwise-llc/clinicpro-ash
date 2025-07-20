# Simple script to run migrations and seed the admin database
# This bypasses the AshAuthentication compilation issues

# Load only the modules we need for admin functionality
Code.require_file("lib/clinicpro/repo.ex")
Code.require_file("lib/clinicpro/admin.ex")
Code.require_file("lib/clinicpro/doctor.ex")
Code.require_file("lib/clinicpro/patient.ex")
Code.require_file("lib/clinicpro/appointment.ex")
Code.require_file("lib/clinicpro/clinic_setting.ex")

# Start Ecto and the Repo
Mix.Task.run("app.start", ["--no-start", "--no-compile", "--no-deps-check"])
{:ok, _} = Application.ensure_all_started(:ecto)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Clinicpro.Repo.start_link()

IO.puts("=== Admin Panel Database Setup ===")

# Run migrations for admin tables
IO.puts("\n[1/3] Running migrations...")
migrations_path = Path.join([:code.priv_dir(:clinicpro), "repo", "migrations"])
Ecto.Migrator.run(Clinicpro.Repo, migrations_path, :up, all: true)

# Create admin user
IO.puts("\n[2/3] Creating admin user...")
admin_params = %{
  email: "admin@clinicpro.com",
  name: "Admin User",
  password: "admin123456",
  password_confirmation: "admin123456",
  role: "Super Admin",
  active: true
}

case Clinicpro.Admin.create(admin_params) do
  {:ok, admin} ->
    IO.puts("✅ Created admin user: #{admin.name} (#{admin.email})")
  
  {:error, changeset} ->
    if Enum.any?(changeset.errors, fn {field, _} -> field == :email end) do
      IO.puts("ℹ️ Admin user already exists")
    else
      IO.puts("❌ Failed to create admin user:")
      IO.inspect(changeset.errors)
    end
end

# Initialize clinic settings
IO.puts("\n[3/3] Initializing clinic settings...")
Clinicpro.ClinicSetting.initialize_defaults()

IO.puts("\n✅ Admin panel database setup completed!")
IO.puts("You can now log in with:")
IO.puts("  Email: admin@clinicpro.com")
IO.puts("  Password: admin123456")
