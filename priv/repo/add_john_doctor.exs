# Add Dr. John Smith with a more secure password
alias Clinicpro.Repo
alias Clinicpro.Doctor

doctor_attrs = %{
  name: "Dr. John Smith",
  specialty: "Cardiology", 
  email: "john.smith@clinicpro.com",
  phone: "555-123-4567",
  password: "CardioSecure2024!@",  # More unique password
  status: "Active",
  active: true
}

case Repo.get_by(Doctor, email: doctor_attrs.email) do
  nil ->
    case Doctor.changeset(%Doctor{}, doctor_attrs) |> Repo.insert() do
      {:ok, doctor} ->
        IO.puts("✅ Created doctor: #{doctor.name} (#{doctor.email})")
        IO.puts("Password: CardioSecure2024!@")
      {:error, changeset} ->
        IO.puts("❌ Failed to create doctor #{doctor_attrs.name}:")
        IO.inspect(changeset.errors)
    end
  _existing ->
    IO.puts("👍 Doctor #{doctor_attrs.name} already exists")
end
