# Script for creating admin users
# Run with: mix run priv/repo/seeds/admin_seeds.exs

alias Clinicpro.Repo
alias Clinicpro.Admin

# Check if the admins table exists
table_exists? =
  try do
    Repo.query!("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'admins')")
    |> Map.get(:rows)
    |> List.first()
    |> List.first()
  rescue
    _ -> false
  end

if table_exists? do
  # Create the initial admin user if none exists
  if Repo.aggregate(Admin, :count) == 0 do
    # Create a super admin user
    admin_params = %{
      email: "admin@clinicpro.com",
      name: "Admin User",
      password: "admin123456",
      password_confirmation: "admin123456",
      role: "Super Admin",
      active: true
    }

    case Admin.create(admin_params) do
      {:ok, admin} ->
        IO.puts("✅ Created admin user: #{admin.name} (#{admin.email})")
      
      {:error, changeset} ->
        IO.puts("❌ Failed to create admin user:")
        IO.inspect(changeset.errors)
    end
  else
    IO.puts("👍 Admin users already exist")
  end
else
  IO.puts("❌ Admins table does not exist yet. Run migrations first.")
end
