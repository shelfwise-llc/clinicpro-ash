# List all doctor accounts
alias Clinicpro.Repo
alias Clinicpro.Doctor

IO.puts("=== DOCTOR ACCOUNTS IN DATABASE ===")

doctors = Repo.all(Doctor)

if Enum.empty?(doctors) do
  IO.puts("No doctors found in database")
else
  Enum.each(doctors, fn doctor ->
    IO.puts("Name: #{doctor.name}")
    IO.puts("Email: #{doctor.email}")
    IO.puts("Specialty: #{doctor.specialty}")
    IO.puts("Status: #{doctor.status}")
    IO.puts("Active: #{doctor.active}")
    IO.puts("---")
  end)
  
  IO.puts("\n=== TEST CREDENTIALS ===")
  IO.puts("Use these exact emails for testing:")
  Enum.each(doctors, fn doctor ->
    IO.puts("Email: #{doctor.email}")
  end)
end
