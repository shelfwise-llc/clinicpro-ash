# Script for creating sample data for testing
# Run with: mix run priv/repo/seeds/sample_data_seeds.exs

alias Clinicpro.Repo
alias Clinicpro.Doctor
alias Clinicpro.Patient
alias Clinicpro.Appointment
alias Clinicpro.ClinicSetting
alias Clinicpro.Admin

# Initialize clinic settings
IO.puts("Initializing clinic settings...")
ClinicSetting.initialize_defaults()

# Create sample doctors if none exist
if Repo.aggregate(Doctor, :count) == 0 do
  IO.puts("Creating sample doctors...")
  
  doctors = [
    %{
      name: "Dr. Jane Smith",
      specialty: "Cardiology",
      email: "jane.smith@clinicpro.com",
      phone: "(555) 123-4567",
      status: "Active",
      active: true
    },
    %{
      name: "Dr. John Doe",
      specialty: "Pediatrics",
      email: "john.doe@clinicpro.com",
      phone: "(555) 234-5678",
      status: "Active",
      active: true
    },
    %{
      name: "Dr. Sarah Johnson",
      specialty: "Neurology",
      email: "sarah.johnson@clinicpro.com",
      phone: "(555) 345-6789",
      status: "On Leave",
      active: true
    },
    %{
      name: "Dr. Michael Brown",
      specialty: "Orthopedics",
      email: "michael.brown@clinicpro.com",
      phone: "(555) 456-7890",
      status: "Active",
      active: true
    },
    %{
      name: "Dr. Emily Wilson",
      specialty: "Dermatology",
      email: "emily.wilson@clinicpro.com",
      phone: "(555) 567-8901",
      status: "Inactive",
      active: false
    }
  ]
  
  Enum.each(doctors, fn doctor_params ->
    case Doctor.create(doctor_params) do
      {:ok, doctor} ->
        IO.puts("✅ Created doctor: #{doctor.name}")
      {:error, changeset} ->
        IO.puts("❌ Failed to create doctor: #{doctor_params.name}")
        IO.inspect(changeset.errors)
    end
  end)
else
  IO.puts("👍 Doctors already exist")
end

# Create sample patients if none exist
if Repo.aggregate(Patient, :count) == 0 do
  IO.puts("Creating sample patients...")
  
  patients = [
    %{
      first_name: "Alice",
      last_name: "Johnson",
      email: "alice.johnson@example.com",
      phone: "(555) 111-2222",
      date_of_birth: ~D[1985-04-15],
      gender: "Female",
      address: "123 Main St, Anytown, USA",
      medical_history: "Allergies: Penicillin",
      insurance_provider: "HealthCare Inc",
      insurance_number: "HC123456789",
      status: "Active",
      active: true
    },
    %{
      first_name: "Bob",
      last_name: "Smith",
      email: "bob.smith@example.com",
      phone: "(555) 222-3333",
      date_of_birth: ~D[1978-09-22],
      gender: "Male",
      address: "456 Oak Ave, Somewhere, USA",
      medical_history: "Hypertension, Type 2 Diabetes",
      insurance_provider: "MediCare Plus",
      insurance_number: "MP987654321",
      status: "Active",
      active: true
    },
    %{
      first_name: "Carol",
      last_name: "Williams",
      email: "carol.williams@example.com",
      phone: "(555) 333-4444",
      date_of_birth: ~D[1992-12-10],
      gender: "Female",
      address: "789 Pine St, Elsewhere, USA",
      medical_history: "Asthma",
      insurance_provider: "InsureCo",
      insurance_number: "IC456789123",
      status: "Active",
      active: true
    },
    %{
      first_name: "David",
      last_name: "Brown",
      email: "david.brown@example.com",
      phone: "(555) 444-5555",
      date_of_birth: ~D[1965-03-28],
      gender: "Male",
      address: "101 Maple Dr, Nowhere, USA",
      medical_history: "Arthritis, High Cholesterol",
      insurance_provider: "HealthGuard",
      insurance_number: "HG789123456",
      status: "Inactive",
      active: false
    },
    %{
      first_name: "Emma",
      last_name: "Davis",
      email: "emma.davis@example.com",
      phone: "(555) 555-6666",
      date_of_birth: ~D[1998-07-03],
      gender: "Female",
      address: "202 Cedar Ln, Anyplace, USA",
      medical_history: "None",
      insurance_provider: "CarePlus",
      insurance_number: "CP321654987",
      status: "Active",
      active: true
    }
  ]
  
  Enum.each(patients, fn patient_params ->
    case Patient.create(patient_params) do
      {:ok, patient} ->
        IO.puts("✅ Created patient: #{Patient.full_name(patient)}")
      {:error, changeset} ->
        IO.puts("❌ Failed to create patient: #{patient_params.first_name} #{patient_params.last_name}")
        IO.inspect(changeset.errors)
    end
  end)
else
  IO.puts("👍 Patients already exist")
end

# Create sample appointments if none exist
if Repo.aggregate(Appointment, :count) == 0 do
  IO.puts("Creating sample appointments...")
  
  # Get all doctors and patients
  doctors = Doctor.list_active()
  patients = Patient.list_active()
  
  if length(doctors) > 0 && length(patients) > 0 do
    # Create appointments for the next 7 days
    today = Date.utc_today()
    
    appointments = [
      %{
        date: Date.add(today, 1),
        start_time: ~T[09:00:00],
        end_time: ~T[09:30:00],
        status: "Scheduled",
        type: "Check-up",
        notes: "Regular check-up appointment",
        doctor_id: Enum.at(doctors, 0).id,
        patient_id: Enum.at(patients, 0).id
      },
      %{
        date: Date.add(today, 1),
        start_time: ~T[10:00:00],
        end_time: ~T[10:30:00],
        status: "Scheduled",
        type: "Consultation",
        notes: "Initial consultation for new symptoms",
        doctor_id: Enum.at(doctors, 1).id,
        patient_id: Enum.at(patients, 1).id
      },
      %{
        date: Date.add(today, 2),
        start_time: ~T[11:00:00],
        end_time: ~T[11:30:00],
        status: "Scheduled",
        type: "Follow-up",
        notes: "Follow-up after treatment",
        doctor_id: Enum.at(doctors, 0).id,
        patient_id: Enum.at(patients, 2).id
      },
      %{
        date: Date.add(today, 3),
        start_time: ~T[14:00:00],
        end_time: ~T[14:30:00],
        status: "Scheduled",
        type: "Check-up",
        notes: "Annual physical examination",
        doctor_id: Enum.at(doctors, 2).id,
        patient_id: Enum.at(patients, 3).id
      },
      %{
        date: Date.add(today, 4),
        start_time: ~T[15:00:00],
        end_time: ~T[15:30:00],
        status: "Scheduled",
        type: "Procedure",
        notes: "Minor procedure scheduled",
        doctor_id: Enum.at(doctors, 3).id,
        patient_id: Enum.at(patients, 4).id
      }
    ]
    
    Enum.each(appointments, fn appointment_params ->
      case Appointment.create(appointment_params) do
        {:ok, appointment} ->
          doctor = Enum.find(doctors, fn d -> d.id == appointment.doctor_id end)
          patient = Enum.find(patients, fn p -> p.id == appointment.patient_id end)
          IO.puts("✅ Created appointment: #{doctor.name} with #{patient.first_name} #{patient.last_name} on #{appointment.date}")
        {:error, changeset} ->
          IO.puts("❌ Failed to create appointment")
          IO.inspect(changeset.errors)
      end
    end)
  else
    IO.puts("⚠️ Cannot create appointments: No active doctors or patients")
  end
else
  IO.puts("👍 Appointments already exist")
end

# Create admin user if none exists
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

IO.puts("✅ Sample data seeding completed!")
