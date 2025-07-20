defmodule ClinicproWeb.PatientFlowController.Appointments do
  use ClinicproWeb, :controller
  alias ClinicproWeb.Plugs.WorkflowValidator
  require Logger

  # Apply authentication plug to ensure only authenticated patients can access
  plug :ensure_authenticated_patient when action in [:index, :new, :create, :show, :cancel]

  # Apply workflow validator for the appointment booking process
  plug WorkflowValidator,
       [workflow: :appointment_booking] when action in [:select_doctor, :select_date, :confirm]

  plug WorkflowValidator,
       [workflow: :appointment_booking, required_step: :select_doctor, redirect_to: "/patient/appointments/new"]
       when action in [:select_date]

  plug WorkflowValidator,
       [workflow: :appointment_booking, required_step: :select_date, redirect_to: "/patient/appointments/date"]
       when action in [:confirm]

  @doc """
  Display the patient's appointments index page.
  """
  def index(conn, _params) do
    patient_id = get_session(conn, :user_id)
    appointments = get_patient_appointments(patient_id)
    
    render(conn, :appointments_index,
      appointments: appointments,
      patient_id: patient_id
    )
  end

  @doc """
  Display a specific appointment for the patient.
  """
  def show(conn, %{"id" => appointment_id}) do
    patient_id = get_session(conn, :user_id)
    
    case get_appointment(appointment_id, patient_id) do
      {:ok, appointment} ->
        render(conn, :appointment_detail,
          appointment: appointment,
          patient_id: patient_id
        )
        
      {:error, reason} ->
        conn
        |> put_flash(:error, "Cannot access appointment: #{reason}")
        |> redirect(to: ~p"/patient/appointments")
    end
  end

  @doc """
  Start the appointment booking process - select doctor.
  """
  def new(conn, _params) do
    patient_id = get_session(conn, :user_id)
    
    # Initialize the workflow for this appointment booking
    conn = WorkflowValidator.init_workflow(conn, :appointment_booking, "booking-#{patient_id}")
    
    # Get available doctors
    available_doctors = get_available_doctors()
    
    render(conn, :select_doctor,
      available_doctors: available_doctors,
      patient_id: patient_id
    )
  end

  @doc """
  Process doctor selection and advance to date selection.
  """
  def select_doctor_submit(conn, %{"doctor_id" => doctor_id}) do
    # Store doctor selection in session
    conn = put_session(conn, :selected_doctor_id, doctor_id)
    
    # Get doctor details
    {:ok, doctor} = get_doctor(doctor_id)
    conn = put_session(conn, :selected_doctor, doctor)
    
    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "patient-#{get_session(conn, :user_id)}")
    
    redirect(conn, to: ~p"/patient/appointments/date")
  end

  @doc """
  Display the date selection page.
  """
  def select_date(conn, _params) do
    patient_id = get_session(conn, :user_id)
    selected_doctor = get_session(conn, :selected_doctor)
    
    # Get available time slots for the selected doctor
    available_slots = get_available_slots(selected_doctor["id"])
    
    render(conn, :select_date,
      available_slots: available_slots,
      selected_doctor: selected_doctor,
      patient_id: patient_id
    )
  end

  @doc """
  Process date selection and advance to confirmation.
  """
  def select_date_submit(conn, %{"slot_id" => slot_id}) do
    # Store slot selection in session
    conn = put_session(conn, :selected_slot_id, slot_id)
    
    # Get slot details
    {:ok, slot} = get_slot(slot_id)
    conn = put_session(conn, :selected_slot, slot)
    
    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "patient-#{get_session(conn, :user_id)}")
    
    redirect(conn, to: ~p"/patient/appointments/confirm")
  end

  @doc """
  Display the appointment confirmation page.
  """
  def confirm(conn, _params) do
    patient_id = get_session(conn, :user_id)
    selected_doctor = get_session(conn, :selected_doctor)
    selected_slot = get_session(conn, :selected_slot)
    
    render(conn, :confirm_appointment,
      selected_doctor: selected_doctor,
      selected_slot: selected_slot,
      patient_id: patient_id
    )
  end

  @doc """
  Process appointment confirmation and create the appointment.
  """
  def confirm_submit(conn, %{"reason" => reason}) do
    patient_id = get_session(conn, :user_id)
    selected_doctor = get_session(conn, :selected_doctor)
    selected_slot = get_session(conn, :selected_slot)
    
    # In a real app, this would create the appointment in the database
    appointment = %{
      id: "appt-#{:rand.uniform(1000)}",
      patient_id: patient_id,
      doctor_id: selected_doctor["id"],
      doctor_name: selected_doctor["name"],
      doctor_specialty: selected_doctor["specialty"],
      date: selected_slot["date"],
      time: selected_slot["time"],
      duration: 30,
      reason: reason,
      status: "Confirmed"
    }
    
    # Log the appointment creation for development purposes
    Logger.info("Appointment created: #{inspect(appointment)}")
    
    # Clear session data
    conn = delete_session(conn, :selected_doctor_id)
    conn = delete_session(conn, :selected_doctor)
    conn = delete_session(conn, :selected_slot_id)
    conn = delete_session(conn, :selected_slot)
    
    # Clear workflow state
    conn = WorkflowValidator.clear_workflow(conn, :appointment_booking)
    
    # Show success message
    conn
    |> put_flash(:info, "Appointment booked successfully")
    |> redirect(to: ~p"/patient/appointments")
  end

  @doc """
  Cancel an existing appointment.
  """
  def cancel(conn, %{"id" => appointment_id}) do
    patient_id = get_session(conn, :user_id)
    
    # In a real app, this would update the appointment status in the database
    Logger.info("Cancelling appointment #{appointment_id} for patient #{patient_id}")
    
    conn
    |> put_flash(:info, "Appointment cancelled successfully")
    |> redirect(to: ~p"/patient/appointments")
  end

  # Private helpers

  defp ensure_authenticated_patient(conn, _opts) do
    if get_session(conn, :user_id) do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access your appointments")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  defp get_patient_appointments(_patient_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    Enum.map(1..5, fn i ->
      %{
        id: "appt-#{i}",
        doctor_name: "Dr. #{["Smith", "Johnson", "Williams", "Brown", "Jones"] |> Enum.at(rem(i, 5))}",
        doctor_specialty: ["Cardiology", "Dermatology", "Family Medicine", "Neurology", "Pediatrics"] |> Enum.at(rem(i, 5)),
        date: Date.utc_today() |> Date.add(i * 2),
        time: "#{10 + i}:00",
        duration: 30,
        status: ["Confirmed", "Completed", "Cancelled", "Rescheduled", "Confirmed"] |> Enum.at(rem(i, 5)),
        reason: ["Regular checkup", "Follow-up", "Consultation", "Prescription renewal", "Test results"] |> Enum.at(rem(i, 5))
      }
    end)
  end

  defp get_appointment(appointment_id, _patient_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database and verify patient access
    
    appointment = %{
      id: appointment_id,
      doctor_name: "Dr. Smith",
      doctor_specialty: "Cardiology",
      date: Date.utc_today() |> Date.add(2),
      time: "10:00",
      duration: 30,
      status: "Confirmed",
      reason: "Regular checkup",
      location: "Clinic Room 3",
      notes: "Please arrive 15 minutes early to complete paperwork.",
      video_link: nil
    }
    
    {:ok, appointment}
  end

  defp get_available_doctors do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    Enum.map(1..5, fn i ->
      %{
        "id" => "doctor-#{i}",
        "name" => "Dr. #{["Smith", "Johnson", "Williams", "Brown", "Jones"] |> Enum.at(rem(i, 5))}",
        "specialty" => ["Cardiology", "Dermatology", "Family Medicine", "Neurology", "Pediatrics"] |> Enum.at(rem(i, 5)),
        "rating" => 4.0 + rem(i, 10) / 10,
        "image" => "/images/doctor-#{i}.jpg"
      }
    end)
  end

  defp get_doctor(doctor_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    doctor = %{
      "id" => doctor_id,
      "name" => "Dr. Smith",
      "specialty" => "Cardiology",
      "rating" => 4.8,
      "image" => "/images/doctor-1.jpg",
      "bio" => "Dr. Smith is a board-certified cardiologist with over 15 years of experience.",
      "education" => "Harvard Medical School",
      "languages" => ["English", "Spanish"]
    }
    
    {:ok, doctor}
  end

  defp get_available_slots(_doctor_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    today = Date.utc_today()
    
    Enum.flat_map(0..6, fn day_offset ->
      date = Date.add(today, day_offset)
      
      Enum.map(9..16, fn hour ->
        %{
          "id" => "slot-#{day_offset}-#{hour}",
          "date" => date,
          "time" => "#{hour}:00",
          "available" => rem(hour + day_offset, 3) != 0
        }
      end)
    end)
  end

  defp get_slot(slot_id) do
    # This is a placeholder implementation
    # In a real app, this would fetch data from a database
    
    # Parse the slot ID to get day offset and hour
    [_, day_offset, hour] = String.split(slot_id, "-")
    {day_offset, _} = Integer.parse(day_offset)
    {hour, _} = Integer.parse(hour)
    
    date = Date.utc_today() |> Date.add(day_offset)
    
    slot = %{
      "id" => slot_id,
      "date" => date,
      "time" => "#{hour}:00",
      "duration" => 30
    }
    
    {:ok, slot}
  end
end
