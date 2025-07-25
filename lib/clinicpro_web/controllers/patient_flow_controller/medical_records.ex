defmodule ClinicproWeb.PatientFlowController.MedicalRecords do
  use ClinicproWeb, :controller
  require Logger

  # Apply authentication plug to ensure only authenticated _patients can access
  plug :ensure_authenticated_patient when action in [:index, :show]

  @doc """
  Display the patient's medical records index _page.
  """
  def index(conn, _params) do
    patient_id = get_session(conn, :user_id)
    medical_records = get_patient_medical_records(patient_id)
    
    render(conn, :medical_records_index,
      medical_records: medical_records,
      patient_id: patient_id
    )
  end

  @doc """
  Display a specific medical record for the patient.
  """
  def show(conn, %{"id" => record_id}) do
    patient_id = get_session(conn, :user_id)
    
    case get_medical_record(record_id, patient_id) do
      {:ok, record} ->
        render(conn, :medical_record_detail,
          record: record,
          patient_id: patient_id
        )
        
      {:error, reason} ->
        conn
        |> put_flash(:error, "Cannot access medical record: #{reason}")
        |> redirect(to: ~p"/patient/medical-records")
    end
  end

  # Private helpers

  defp ensure_authenticated_patient(conn, _opts) do
    if get_session(conn, :user_id) do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access your medical records")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  defp get_patient_medical_records(_patient_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    Enum.map(1..5, fn i ->
      %{
        id: "record-#{i}",
        date: Date.utc_today() |> Date.add(-i * 30),
        doctor_name: "Dr. #{["Smith", "Johnson", "Williams", "Brown", "Jones"] |> Enum.at(rem(i, 5))}",
        diagnosis: ["Common cold", "Annual checkup", "Sprained ankle", "Allergic reaction", "Migraine"] |> Enum.at(rem(i, 5)),
        has_prescriptions: rem(i, 2) == 0
      }
    end)
  end

  defp get_medical_record(record_id, _patient_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database and verify patient access
    
    record = %{
      id: record_id,
      date: Date.utc_today() |> Date.add(-30),
      doctor_name: "Dr. Smith",
      doctor_specialty: "General Practice",
      diagnosis: "Common cold",
      treatment_plan: "Rest, fluids, and over-the-counter medication",
      follow_up: "Return in 2 weeks if symptoms persist",
      vitals: %{
        blood_pressure: "120/80",
        heart_rate: "72 bpm",
        temperature: "37.0°C"
      },
      prescriptions: [
        %{
          medication_name: "Acetaminophen",
          dosage: "500mg",
          frequency: "Every 6 hours as needed",
          duration: "5 days",
          instructions: "Take with food"
        },
        %{
          medication_name: "Cough Syrup",
          dosage: "10ml",
          frequency: "Every 4-6 hours as needed",
          duration: "5 days",
          instructions: "Take as needed for cough"
        }
      ],
      lab_results: [
        %{
          test_name: "Complete Blood Count",
          date: Date.utc_today() |> Date.add(-28),
          status: "Normal",
          notes: "All values within normal range"
        }
      ],
      notes: "Patient presented with symptoms of common cold including runny nose, sore throat, and mild fever."
    }
    
    {:ok, record}
  end
end
