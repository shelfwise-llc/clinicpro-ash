# Create test patients and appointments for doctor testing
alias Clinicpro.Repo
alias Clinicpro.{Doctor, Patient, Appointment}

IO.puts("Creating test data for doctor functionality...")

# Get a test doctor
doctor = Repo.get_by(Doctor, email: "test@clinicpro.com")

if doctor do
  IO.puts("Using doctor: #{doctor.name}")
  
  # Create test patients
  patients_data = [
    %{
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "555-0001",
      date_of_birth: ~D[1985-06-15],
      gender: "Male",
      address: "123 Main St, City, State",
      active: true
    },
    %{
      first_name: "Jane",
      last_name: "Smith",
      email: "jane.smith@example.com", 
      phone: "555-0002",
      date_of_birth: ~D[1990-03-22],
      gender: "Female",
      address: "456 Oak Ave, City, State",
      active: true
    },
    %{
      first_name: "Bob",
      last_name: "Johnson",
      email: "bob.johnson@example.com",
      phone: "555-0003", 
      date_of_birth: ~D[1978-11-08],
      gender: "Male",
      address: "789 Pine St, City, State",
      active: true
    }
  ]
  
  created_patients = Enum.map(patients_data, fn patient_attrs ->
    case Repo.get_by(Patient, email: patient_attrs.email) do
      nil ->
        case Patient.changeset(%Patient{}, patient_attrs) |> Repo.insert() do
          {:ok, patient} ->
            IO.puts("✅ Created patient: #{patient.name}")
            patient
          {:error, changeset} ->
            IO.puts("❌ Failed to create patient #{patient_attrs.name}")
            IO.inspect(changeset.errors)
            nil
        end
      existing ->
        IO.puts("👍 Patient #{existing.name} already exists")
        existing
    end
  end)
  |> Enum.filter(& &1)
  
  # Create test appointments
  if length(created_patients) > 0 do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)
    next_week = Date.add(today, 7)
    
    appointments_data = [
      %{
        patient_id: Enum.at(created_patients, 0).id,
        doctor_id: doctor.id,
        date: today,
        start_time: ~T[09:00:00],
        end_time: ~T[09:30:00],
        status: "Scheduled",
        type: "Regular checkup",
        notes: "Annual physical examination"
      },
      %{
        patient_id: Enum.at(created_patients, 1).id,
        doctor_id: doctor.id,
        date: today,
        start_time: ~T[14:30:00],
        end_time: ~T[15:00:00],
        status: "Scheduled", 
        type: "Follow-up visit",
        notes: "Follow-up on blood pressure medication"
      },
      %{
        patient_id: Enum.at(created_patients, 2).id,
        doctor_id: doctor.id,
        date: tomorrow,
        start_time: ~T[10:00:00],
        end_time: ~T[10:30:00],
        status: "Scheduled",
        type: "Consultation",
        notes: "Discuss test results"
      },
      %{
        patient_id: Enum.at(created_patients, 0).id,
        doctor_id: doctor.id,
        date: next_week,
        start_time: ~T[11:00:00],
        end_time: ~T[11:30:00],
        status: "Scheduled",
        type: "Routine visit",
        notes: "Quarterly health check"
      }
    ]
    
    Enum.each(appointments_data, fn appointment_attrs ->
      case Appointment.changeset(%Appointment{}, appointment_attrs) |> Repo.insert() do
        {:ok, appointment} ->
          patient = Enum.find(created_patients, &(&1.id == appointment.patient_id))
          IO.puts("✅ Created appointment: #{patient.name} on #{Date.to_string(DateTime.to_date(appointment.appointment_date))}")
        {:error, changeset} ->
          IO.puts("❌ Failed to create appointment")
          IO.inspect(changeset.errors)
      end
    end)
  end
  
  IO.puts("\n=== TEST DATA CREATED ===")
  IO.puts("Doctor: #{doctor.name} (#{doctor.email})")
  IO.puts("Patients: #{length(created_patients)}")
  IO.puts("Use credentials: test@clinicpro.com | TestSecure2024!")
  IO.puts("Login at: http://localhost:4000/doctor")
  
else
  IO.puts("❌ Test doctor not found. Please run doctor seeds first.")
end
