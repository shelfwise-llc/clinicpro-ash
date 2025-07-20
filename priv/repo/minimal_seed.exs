# Minimal seeding script that only creates an admin user
# This script uses Ecto directly to insert an admin into the database

alias Clinicpro.Repo
alias Clinicpro.Admin

# Create admin user if it doesn't exist
case Repo.get_by(Admin, email: "admin@clinicpro.com") do
  nil ->
    # Create admin with hashed password
    %Admin{}
    |> Admin.changeset(%{
      email: "admin@clinicpro.com",
      password: "admin123", # This will be hashed by the changeset
      first_name: "Admin",
      last_name: "User",
      is_active: true
    })
    |> Repo.insert!()
    
    IO.puts("Admin user created successfully")
    
  _admin ->
    IO.puts("Admin user already exists")
end

IO.puts("\nMinimal seeding completed successfully!")
