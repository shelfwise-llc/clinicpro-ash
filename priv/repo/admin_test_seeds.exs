# Script for creating test admin accounts
# Run with: mix run priv/repo/admin_test_seeds.exs

alias Clinicpro.Repo
alias Clinicpro.Admin

# Test admin accounts
admin_accounts = [
  %{
    name: "Super Admin",
    email: "admin@clinicpro.com",
    password: "admin123",
    password_confirmation: "admin123",
    role: "Super Admin",
    active: true
  },
  %{
    name: "Test Admin",
    email: "test.admin@clinicpro.com",
    password: "test123",
    password_confirmation: "test123",
    role: "Admin",
    active: true
  }
]

IO.puts("Creating test admin accounts...")

Enum.each(admin_accounts, fn admin_attrs ->
  email = admin_attrs.email

  case Repo.get_by(Admin, email: email) do
    nil ->
      case Admin.create(admin_attrs) do
        {:ok, admin} ->
          IO.puts("✅ Created admin: #{admin.name} (#{admin.email})")

        {:error, changeset} ->
          IO.puts("❌ Failed to create admin #{admin_attrs.name}:")
          IO.inspect(changeset.errors)
      end

    _existing ->
      IO.puts("👍 Admin #{admin_attrs.name} already exists")
  end
end)

IO.puts("\n=== TEST ADMIN CREDENTIALS ===")
IO.puts("Email: admin@clinicpro.com | Password: admin123")
IO.puts("Email: test.admin@clinicpro.com | Password: test123")
IO.puts("\nUse these credentials to test the admin portal at:")
IO.puts("http://localhost:4000/admin/login")
