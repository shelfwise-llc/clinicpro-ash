# Script for creating secure test doctor accounts
# Run with: mix run priv/repo/doctor_seeds_secure.exs

alias Clinicpro.Repo
alias Clinicpro.Doctor

# Secure test doctor accounts with strong passwords
doctor_accounts = [
  %{
    name: "Dr. John Smith",
    specialty: "Cardiology",
    email: "john.smith@clinicpro.com",
    phone: "555-123-4567",
    password: "SecureDoctor123!",
    status: "Active",
    active: true
  },
  %{
    name: "Dr. Sarah Johnson", 
    specialty: "Pediatrics",
    email: "sarah.johnson@clinicpro.com",
    phone: "555-234-5678",
    password: "MedicalSecure456@",
    status: "Active",
    active: true
  },
  %{
    name: "Dr. Michael Chen",
    specialty: "Neurology", 
    email: "michael.chen@clinicpro.com",
    phone: "555-345-6789",
    password: "NeuroSecure789#",
    status: "Active",
    active: true
  },
  %{
    name: "Dr. Test Doctor",
    specialty: "General Practice",
    email: "test@clinicpro.com", 
    phone: "555-999-0000",
    password: "TestSecure2024!",
    status: "Active",
    active: true
  }
]

IO.puts("Creating secure test doctor accounts...")

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

IO.puts("\n=== SECURE TEST DOCTOR CREDENTIALS ===")
IO.puts("Email: john.smith@clinicpro.com | Password: SecureDoctor123!")
IO.puts("Email: sarah.johnson@clinicpro.com | Password: MedicalSecure456@") 
IO.puts("Email: michael.chen@clinicpro.com | Password: NeuroSecure789#")
IO.puts("Email: test@clinicpro.com | Password: TestSecure2024!")
IO.puts("\nThese passwords meet production security requirements:")
IO.puts("- 12+ characters")
IO.puts("- Uppercase, lowercase, numbers, special characters")
IO.puts("- Not common passwords")
IO.puts("\nUse these credentials to test the enhanced doctor portal at:")
IO.puts("http://localhost:4000/doctor")
