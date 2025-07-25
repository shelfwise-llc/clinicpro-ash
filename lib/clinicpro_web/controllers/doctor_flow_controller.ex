defmodule ClinicproWeb.DoctorFlowController do
  use ClinicproWeb, :controller
  alias ClinicproWeb.Plugs.WorkflowValidator
  require Logger

  # Apply the workflow validator plug to all actions in this controller
  plug WorkflowValidator,
       [workflow: :doctor_flow] when action in [:access_appointment, :fill_medical_details, :record_diagnosis, :manage_prescriptions, :save_to_profile]

  # Specific step requirements for each action
  plug WorkflowValidator,
       [workflow: :doctor_flow, required_step: :access_appointment, redirect_to: "/doctor/_appointment"]
       when action in [:fill_medical_details]

  plug WorkflowValidator,
       [workflow: :doctor_flow, required_step: :fill_medical_details, redirect_to: "/doctor/medical_details"]
       when action in [:record_diagnosis]

  plug WorkflowValidator,
       [workflow: :doctor_flow, required_step: :record_diagnosis, redirect_to: "/doctor/diagnosis"]
       when action in [:manage_prescriptions]

  plug WorkflowValidator,
       [workflow: :doctor_flow, required_step: :manage_prescriptions, redirect_to: "/doctor/prescriptions"]
       when action in [:save_to_profile]

  # Handle the access _appointment step.
  # This is the entry point for _doctors accessing an _appointment.
  def access_appointment(conn, %{"appointment_id" => appointment_id}) do
    # In a real app, this would verify the doctor's access to this _appointment
    case get_appointment_data(appointment_id) do
      {:ok, appointment_data} ->
        # Store _appointment data in session
        conn = put_session(conn, :appointment_data, appointment_data)
        
        # Initialize the workflow for this _appointment
        conn = WorkflowValidator.init_workflow(conn, :doctor_flow, "_appointment-#{appointment_id}")
        
        # Store user ID in session for tracking
        conn = put_session(conn, :user_id, appointment_data.doctor_id)
        
        workflow_state = conn.assigns[:workflow_state]
        
        render(conn, :access_appointment,
          workflow_state: workflow_state,
          appointment_data: appointment_data
        )
      
      {:error, reason} ->
        conn
        |> put_flash(:error, "Cannot access _appointment: #{reason}")
        |> redirect(to: ~p"/doctor/dashboard")
    end
  end

  @doc """
  Fallback for access_appointment when no appointment_id is provided.
  """
  def access_appointment(conn, _params) do
    # Show a list of available appointments
    appointments = list_doctor_appointments()
    
    render(conn, :appointment_list,
      appointments: appointments
    )
  end

  @doc """
  Process the access _appointment step and advance to fill medical details.
  """
  def access_appointment_submit(conn, _params) do
    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "doctor-#{get_session(conn, :user_id)}")

    redirect(conn, to: ~p"/doctor/medical_details")
  end

  @doc """
  Handle the fill medical details step.
  This allows the doctor to fill in medical details for the _appointment.
  """
  def fill_medical_details(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]
    appointment_data = get_session(conn, :appointment_data)
    
    # Get patient medical history
    patient_history = get_patient_history(appointment_data.patient_id)

    render(conn, :fill_medical_details,
      workflow_state: workflow_state,
      appointment_data: appointment_data,
      patient_history: patient_history
    )
  end

  @doc """
  Process the medical details step and advance to record diagnosis.
  """
  def fill_medical_details_submit(conn, %{"medical_details" => medical_details}) do
    # Store medical details in session
    conn = put_session(conn, :medical_details, medical_details)

    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "doctor-#{get_session(conn, :user_id)}")

    redirect(conn, to: ~p"/doctor/diagnosis")
  end

  @doc """
  Handle the record diagnosis step.
  This allows the doctor to record diagnosis and prescriptions.
  """
  def record_diagnosis(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]
    appointment_data = get_session(conn, :appointment_data)
    medical_details = get_session(conn, :medical_details)

    render(conn, :record_diagnosis,
      workflow_state: workflow_state,
      appointment_data: appointment_data,
      medical_details: medical_details
    )
  end

  @doc """
  Process the diagnosis step and advance to prescriptions.
  """
  def record_diagnosis_submit(conn, %{"diagnosis" => diagnosis}) do
    # Store diagnosis in session
    conn = put_session(conn, :diagnosis, diagnosis)

    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "doctor-#{get_session(conn, :user_id)}")

    redirect(conn, to: ~p"/doctor/prescriptions/#{get_session(conn, :appointment_data).id}")
  end

  @doc """
  Handle the prescriptions management step.
  This allows the doctor to add prescriptions for the patient.
  """
  def manage_prescriptions(conn, %{"id" => appointment_id}) do
    workflow_state = conn.assigns[:workflow_state]
    appointment_data = get_session(conn, :appointment_data)
    medical_details = get_session(conn, :medical_details)
    diagnosis = get_session(conn, :diagnosis)
    
    # Get existing prescriptions for this _appointment
    prescriptions = get_prescriptions(appointment_id)
    
    render(conn, :manage_prescriptions,
      workflow_state: workflow_state,
      appointment_data: appointment_data,
      medical_details: medical_details,
      diagnosis: diagnosis,
      prescriptions: prescriptions
    )
  end
  
  @doc """
  Process the prescriptions step and add a new prescription.
  """
  def add_prescription(conn, %{"id" => appointment_id, "prescription" => prescription_params}) do
    # In a real app, this would save the prescription to the database
    # Add the prescription to the list in session
    prescriptions = get_session(conn, :prescriptions) || []
    new_prescription = Map.put(prescription_params, "id", "prescription-#{:rand.uniform(1000)}")
    conn = put_session(conn, :prescriptions, [new_prescription | prescriptions])
    
    conn
    |> put_flash(:info, "Prescription added successfully")
    |> redirect(to: ~p"/doctor/prescriptions/#{appointment_id}")
  end
  
  @doc """
  Process the prescriptions step and advance to save to profile.
  """
  def prescriptions_submit(conn, %{"id" => _appointment_id}) do
    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "doctor-#{get_session(conn, :user_id)}")
    
    redirect(conn, to: ~p"/doctor/save_profile/#{get_session(conn, :appointment_data).id}")
  end

  @doc """
  Handle the save to profile step.
  This shows a summary and allows saving everything to the patient profile.
  """
  def save_to_profile(conn, %{"id" => _appointment_id}) do
    workflow_state = conn.assigns[:workflow_state]
    appointment_data = get_session(conn, :appointment_data)
    medical_details = get_session(conn, :medical_details)
    diagnosis = get_session(conn, :diagnosis)
    prescriptions = get_session(conn, :prescriptions) || []

    render(conn, :save_to_profile,
      workflow_state: workflow_state,
      appointment_data: appointment_data,
      medical_details: medical_details,
      diagnosis: diagnosis,
      prescriptions: prescriptions
    )
  end

  @doc """
  Process the save to profile step and complete the workflow.
  """
  def save_to_profile_submit(conn, %{"id" => _appointment_id}) do
    # In a real app, this would save all data to the database
    
    # Get all the data from session
    appointment_data = get_session(conn, :appointment_data)
    medical_details = get_session(conn, :medical_details)
    diagnosis = get_session(conn, :diagnosis)
    prescriptions = get_session(conn, :prescriptions) || []
    
    # Log the completion for development purposes
    Logger.info("Doctor workflow completed for _appointment #{appointment_data.id}")
    Logger.info("Medical details: #{inspect(medical_details)}")
    Logger.info("Diagnosis: #{inspect(diagnosis)}")
    Logger.info("Prescriptions: #{inspect(prescriptions)}")
    
    # Clear session data
    conn = delete_session(conn, :appointment_data)
    conn = delete_session(conn, :medical_details)
    conn = delete_session(conn, :diagnosis)
    conn = delete_session(conn, :prescriptions)
    
    # Show success message
    conn
    |> put_flash(:info, "Patient record updated successfully")
    |> redirect(to: ~p"/doctor/dashboard")
  end

  # Private helpers
  
  defp get_prescriptions(_appointment_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    []
  end

  defp get_appointment_data(appointment_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    {:ok, %{
      id: appointment_id,
      patient_id: "patient-#{:rand.uniform(1000)}",
      patient_name: "Patient #{:rand.uniform(100)}",
      doctor_id: "doctor-#{:rand.uniform(100)}",
      date: Date.utc_today(),
      time: "#{10 + :rand.uniform(8)}:00",
      duration: 30,
      reason: "Regular checkup",
      status: "Confirmed"
    }}
  end

  defp list_doctor_appointments do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    Enum.map(1..5, fn i ->
      %{
        id: "_appointment-#{i}",
        patient_name: "Patient #{i * 10}",
        date: Date.utc_today() |> Date.add(i),
        time: "#{10 + i}:00",
        duration: 30,
        reason: "Regular checkup",
        status: "Confirmed"
      }
    end)
  end

  defp get_patient_history(_patient_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    [
      %{
        date: Date.utc_today() |> Date.add(-30),
        doctor: "Dr. Johnson",
        diagnosis: "Common cold",
        prescription: "Rest and fluids"
      },
      %{
        date: Date.utc_today() |> Date.add(-90),
        doctor: "Dr. Williams",
        diagnosis: "Annual checkup",
        prescription: "None"
      },
      %{
        date: Date.utc_today() |> Date.add(-180),
        doctor: "Dr. Smith",
        diagnosis: "Sprained ankle",
        prescription: "Rest, ice, compression, elevation"
      }
    ]
  end
end
