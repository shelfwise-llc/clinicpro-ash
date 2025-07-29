# Script for creating test doctor accounts with authentication
# Run with: mix run priv/repo/doctor_seeds.exs

alias Clinicpro.Repo
alias Clinicpro.Doctor

# Test doctor accounts with credentials
doctor_accounts = [
  %{
    name: "Dr. John Smith",
    specialty: "Cardiology",
    email: "john.smith@clinicpro.com",
    phone: "555-123-4567",
    password: "doctor123",
    status: "Active",
    active: true
  },
  %{
    name: "Dr. Sarah Johnson",
    specialty: "Pediatrics",
    email: "sarah.johnson@clinicpro.com",
    phone: "555-234-5678",
    password: "doctor123",
    status: "Active",
    active: true
  },
  %{
    name: "Dr. Michael Chen",
    specialty: "Neurology",
    email: "michael.chen@clinicpro.com",
    phone: "555-345-6789",
    password: "doctor123",
    status: "Active",
    active: true
  },
  %{
    name: "Dr. Test Doctor",
    specialty: "General Practice",
    email: "test@clinicpro.com",
    phone: "555-999-0000",
    password: "test123",
    status: "Active",
    active: true
  }
]

IO.puts("Creating test doctor accounts...")

Enum.each(doctor_accounts, fn doctor_attrs ->
  email = doctor_attrs.email

  case Repo.get_by(Doctor, email: email) do
    nil ->
      case Doctor.changeset(%Doctor{}, doctor_attrs) |> Repo.insert() do
        {:ok, doctor} ->
          IO.puts("✅ Created doctor: #{doctor.name} (#{doctor.email})")

        {:error, changeset} ->
          IO.puts("❌ Failed to create doctor #{doctor_attrs.name}:")
          IO.inspect(changeset.errors)
      end

    _existing ->
      IO.puts("👍 Doctor #{doctor_attrs.name} already exists")
  end
end)

IO.puts("\n=== TEST DOCTOR CREDENTIALS ===")
IO.puts("Email: john.smith@clinicpro.com | Password: doctor123")
IO.puts("Email: sarah.johnson@clinicpro.com | Password: doctor123")
IO.puts("Email: michael.chen@clinicpro.com | Password: doctor123")
IO.puts("Email: test@clinicpro.com | Password: test123")
IO.puts("\nUse these credentials to test the doctor portal at:")
IO.puts("http://localhost:4000/doctor")
