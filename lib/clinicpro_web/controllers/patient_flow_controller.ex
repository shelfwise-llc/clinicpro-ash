defmodule ClinicproWeb.PatientFlowController do
  use ClinicproWeb, :controller
  alias ClinicproWeb.Plugs.WorkflowValidator
  require Logger

  # Apply the workflow validator plug to all actions in this controller
  plug WorkflowValidator,
       [workflow: :patient_flow]
       when action in [:receive_link, :welcome, :confirm_details, :booking_confirmation]

  # Specific step requirements for each action
  plug WorkflowValidator,
       [workflow: :patient_flow, required_step: :receive_link, redirect_to: "/patient/link"]
       when action in [:welcome]

  plug WorkflowValidator,
       [workflow: :patient_flow, required_step: :welcome, redirect_to: "/patient/welcome"]
       when action in [:confirm_details]

  plug WorkflowValidator,
       [workflow: :patient_flow, required_step: :confirm_details, redirect_to: "/patient/confirm"]
       when action in [:booking_confirmation]

  # Handle the receive link step.
  # This is the entry point for _patients who receive a link to their appointment.
  def receive_link(conn, %{"token" => token}) do
    # Validate the token (in a real app, this would verify against a database)
    case validate_appointment_token(token) do
      {:ok, appointment_data} ->
        # Store appointment data in session
        conn = put_session(conn, :appointment_data, appointment_data)

        # Initialize the workflow for this appointment
        conn =
          WorkflowValidator.init_workflow(
            conn,
            :patient_flow,
            "appointment-#{appointment_data.id}"
          )

        # Store user ID in session for tracking
        conn = put_session(conn, :user_id, appointment_data.patient_id)

        # Advance to the first step
        conn = WorkflowValidator.advance_workflow(conn, "patient-#{appointment_data.patient_id}")

        redirect(conn, to: ~p"/patient/welcome")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Invalid appointment link: #{reason}")
        |> redirect(to: ~p"/")
    end
  end

  @doc """
  Fallback for receive_link when no token is provided.
  """
  def receive_link(conn, _params) do
    conn
    |> put_flash(:error, "No appointment token provided")
    |> redirect(to: ~p"/")
  end

  @doc """
  Handle the welcome step.
  This shows a welcome message to the patient with basic appointment info.
  """
  def welcome(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]
    appointment_data = get_session(conn, :appointment_data)

    render(conn, :welcome,
      workflow_state: workflow_state,
      appointment_data: appointment_data
    )
  end

  @doc """
  Process the welcome step and advance to confirm details.
  """
  def welcome_submit(conn, _params) do
    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "patient-#{get_session(conn, :user_id)}")

    redirect(conn, to: ~p"/patient/confirm")
  end

  @doc """
  Handle the confirm details step.
  This allows the patient to confirm their appointment details.
  """
  def confirm_details(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]
    appointment_data = get_session(conn, :appointment_data)

    render(conn, :confirm_details,
      workflow_state: workflow_state,
      appointment_data: appointment_data
    )
  end

  @doc """
  Process the confirm details step and advance to booking confirmation.
  """
  def confirm_details_submit(conn, %{"confirmation" => confirmation_params}) do
    # Store confirmation details in session
    conn = put_session(conn, :confirmation_details, confirmation_params)

    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "patient-#{get_session(conn, :user_id)}")

    redirect(conn, to: ~p"/patient/confirmation")
  end

  @doc """
  Handle the booking confirmation step.
  This shows the final confirmation to the patient.
  """
  def booking_confirmation(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]
    appointment_data = get_session(conn, :appointment_data)
    confirmation_details = get_session(conn, :confirmation_details)

    render(conn, :booking_confirmation,
      workflow_state: workflow_state,
      appointment_data: appointment_data,
      confirmation_details: confirmation_details
    )
  end

  # Private helpers

  defp validate_appointment_token(_token) do
    # This is a placeholder implementation
    # In a real app, this would verify the token against a database

    # For development, accept any token and generate mock data
    {:ok,
     %{
       id: "appt-#{:rand.uniform(1000)}",
       patient_id: "patient-#{:rand.uniform(1000)}",
       doctor_name: "Dr. Smith",
       specialty: "Cardiology",
       date: Date.utc_today() |> Date.add(:rand.uniform(10)),
       time: "#{10 + :rand.uniform(8)}:00",
       duration: 30,
       location: "Clinic Room #{:rand.uniform(10)}"
     }}
  end
end
