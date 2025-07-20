# Admin seeding script that bypasses AshAuthentication
# This script directly inserts an admin user into the database

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

# Create sample doctors
doctors = [
  %{
    first_name: "John",
    last_name: "Smith",
    specialty: "Cardiology",
    email: "john.smith@clinicpro.com",
    phone: "555-123-4567",
    active: true
  },
  %{
    first_name: "Sarah",
    last_name: "Johnson",
    specialty: "Pediatrics",
    email: "sarah.johnson@clinicpro.com",
    phone: "555-234-5678",
    active: true
  },
  %{
    first_name: "Michael",
    last_name: "Chen",
    specialty: "Neurology",
    email: "michael.chen@clinicpro.com",
    phone: "555-345-6789",
    active: true
  }
]

# Insert doctors
Enum.each(doctors, fn doctor_params ->
  case Clinicpro.Doctor.get_by_email(doctor_params.email) do
    nil ->
      {:ok, _doctor} = Clinicpro.Doctor.create(doctor_params)
      IO.puts("Created doctor: #{doctor_params.first_name} #{doctor_params.last_name}")
    _doctor ->
      IO.puts("Doctor already exists: #{doctor_params.first_name} #{doctor_params.last_name}")
  end
end)

# Create sample patients
patients = [
  %{
    first_name: "Alice",
    last_name: "Brown",
    date_of_birth: ~D[1985-06-15],
    email: "alice.brown@example.com",
    phone: "555-456-7890",
    address: "123 Main St, Anytown, USA",
    active: true
  },
  %{
    first_name: "Robert",
    last_name: "Garcia",
    date_of_birth: ~D[1972-11-22],
    email: "robert.garcia@example.com",
    phone: "555-567-8901",
    address: "456 Oak Ave, Somewhere, USA",
    active: true
  },
  %{
    first_name: "Emily",
    last_name: "Wilson",
    date_of_birth: ~D[1990-03-08],
    email: "emily.wilson@example.com",
    phone: "555-678-9012",
    address: "789 Pine St, Nowhere, USA",
    active: true
  }
]

# Insert patients
Enum.each(patients, fn patient_params ->
  case Clinicpro.Patient.get_by_email(patient_params.email) do
    nil ->
      {:ok, _patient} = Clinicpro.Patient.create(patient_params)
      IO.puts("Created patient: #{patient_params.first_name} #{patient_params.last_name}")
    _patient ->
      IO.puts("Patient already exists: #{patient_params.first_name} #{patient_params.last_name}")
  end
end)

# Create sample appointments
# First get the doctors and patients
doctors = Clinicpro.Doctor.list_active()
patients = Clinicpro.Patient.list_active()

if length(doctors) > 0 && length(patients) > 0 do
  # Create appointments for the next 7 days
  today = Date.utc_today()
  
  appointments = [
    %{
      doctor_id: Enum.at(doctors, 0).id,
      patient_id: Enum.at(patients, 0).id,
      date: Date.add(today, 1),
      start_time: ~T[09:00:00],
      end_time: ~T[09:30:00],
      status: "scheduled",
      notes: "Regular checkup"
    },
    %{
      doctor_id: Enum.at(doctors, 1).id,
      patient_id: Enum.at(patients, 1).id,
      date: Date.add(today, 2),
      start_time: ~T[10:00:00],
      end_time: ~T[10:30:00],
      status: "scheduled",
      notes: "Follow-up appointment"
    },
    %{
      doctor_id: Enum.at(doctors, 2).id,
      patient_id: Enum.at(patients, 2).id,
      date: Date.add(today, 3),
      start_time: ~T[14:00:00],
      end_time: ~T[14:30:00],
      status: "scheduled",
      notes: "New patient consultation"
    }
  ]
  
  # Insert appointments
  Enum.each(appointments, fn appointment_params ->
    {:ok, _appointment} = Clinicpro.Appointment.create(appointment_params)
    IO.puts("Created appointment for #{Date.to_string(appointment_params.date)} at #{Time.to_string(appointment_params.start_time)}")
  end)
else
  IO.puts("Cannot create appointments: No doctors or patients available")
end

IO.puts("Seeding completed successfully!")
