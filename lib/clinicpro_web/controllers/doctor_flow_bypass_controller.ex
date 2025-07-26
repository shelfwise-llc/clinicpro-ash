defmodule ClinicproWeb.DoctorFlowBypassController do
  @moduledoc """
  Doctor Flow Controller that bypasses AshAuthentication issues.

  This controller implements the doctor workflow steps:
  1. List appointments
  2. Access _appointment details
  3. Fill medical details
  4. Record diagnosis
  5. Complete _appointment

  It uses mock modules and workflow validation to ensure proper workflow state transitions.
  """

  use ClinicproWeb, :controller
  alias Clinicpro.WorkflowValidator

  @doc """
  Lists all appointments for the current doctor.
  """
  def list_appointments(conn, _params) do
    # In a real controller, we would get the current user from the session
    # and fetch their appointments from the database
    # Here we're using mock data

    # Initialize workflow state
    workflow_state = %{
      workflow_type: :doctor_flow,
      current_step: :list_appointments
    }

    # Store workflow state in session
    conn = put_session(conn, :workflow_state, workflow_state)

    # Get appointments for the doctor
    # In a real controller, this would be fetched from the database
    appointments = get_mock_appointments()

    # Render the appointments list
    render(conn, :list_appointments, appointments: appointments)
  end

  @doc """
  Shows details for a specific _appointment.
  """
  def access_appointment(conn, %{"id" => appointment_id}) do
    # Get workflow state from session
    workflow_state =
      get_session(conn, :workflow_state) ||
        %{
          workflow_type: :doctor_flow,
          current_step: :list_appointments
        }

    # Validate transition
    case WorkflowValidator.validate_transition(workflow_state, :access_appointment) do
      :ok ->
        # Get _appointment details
        # In a real controller, this would be fetched from the database
        _appointment = get_mock_appointment(appointment_id)

        if _appointment do
          # Update workflow state
          workflow_state = %{
            workflow_state
            | current_step: :access_appointment,
              appointment_id: appointment_id
          }

          # Store workflow state in session
          conn = put_session(conn, :workflow_state, workflow_state)

          # Render the _appointment details
          render(conn, :access_appointment, _appointment: _appointment)
        else
          # Appointment not found
          conn
          |> put_flash(:error, "Appointment not found")
          |> redirect(to: ~p"/doctor/appointments")
        end

      {:error, reason} ->
        # Invalid transition
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/doctor/appointments")
    end
  end

  @doc """
  Shows form for entering medical details.
  """
  def fill_medical_details_form(conn, %{"id" => appointment_id}) do
    # Get workflow state from session
    workflow_state =
      get_session(conn, :workflow_state) ||
        %{
          workflow_type: :doctor_flow,
          current_step: :list_appointments
        }

    # Validate transition
    case WorkflowValidator.validate_transition(workflow_state, :fill_medical_details) do
      :ok ->
        # Get _appointment details
        # In a real controller, this would be fetched from the database
        _appointment = get_mock_appointment(appointment_id)

        if _appointment do
          # Update workflow state
          workflow_state = %{
            workflow_state
            | current_step: :fill_medical_details,
              appointment_id: appointment_id
          }

          # Store workflow state in session
          conn = put_session(conn, :workflow_state, workflow_state)

          # Render the medical details form
          render(conn, :fill_medical_details_form, _appointment: _appointment)
        else
          # Appointment not found
          conn
          |> put_flash(:error, "Appointment not found")
          |> redirect(to: ~p"/doctor/appointments")
        end

      {:error, reason} ->
        # Invalid transition
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/doctor/appointments")
    end
  end

  @doc """
  Processes the medical details form submission.
  """
  def fill_medical_details(conn, %{"id" => appointment_id, "medical_details" => medical_details}) do
    # Get workflow state from session
    workflow_state =
      get_session(conn, :workflow_state) ||
        %{
          workflow_type: :doctor_flow,
          current_step: :list_appointments
        }

    # Validate medical details
    case WorkflowValidator.validate_medical_details(medical_details) do
      :ok ->
        # Validate transition
        case WorkflowValidator.validate_transition(workflow_state, :record_diagnosis) do
          :ok ->
            # Update workflow state
            workflow_state = %{
              workflow_state
              | current_step: :record_diagnosis,
                appointment_id: appointment_id,
                medical_details: medical_details
            }

            # Store workflow state in session
            conn = put_session(conn, :workflow_state, workflow_state)

            # Redirect to diagnosis form
            redirect(conn, to: ~p"/doctor/appointments/#{appointment_id}/diagnosis")

          {:error, reason} ->
            # Invalid transition
            conn
            |> put_flash(:error, reason)
            |> redirect(to: ~p"/doctor/appointments")
        end

      {:error, reason} ->
        # Invalid medical details
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/doctor/appointments/#{appointment_id}/medical_details")
    end
  end

  @doc """
  Shows form for entering diagnosis.
  """
  def record_diagnosis_form(conn, %{"id" => appointment_id}) do
    # Get workflow state from session
    workflow_state =
      get_session(conn, :workflow_state) ||
        %{
          workflow_type: :doctor_flow,
          current_step: :list_appointments
        }

    # Validate step data
    case WorkflowValidator.validate_step_data(workflow_state) do
      :ok ->
        # Get _appointment details
        # In a real controller, this would be fetched from the database
        _appointment = get_mock_appointment(appointment_id)

        if _appointment do
          # Render the diagnosis form
          render(conn, :record_diagnosis_form,
            _appointment: _appointment,
            medical_details: workflow_state[:medical_details]
          )
        else
          # Appointment not found
          conn
          |> put_flash(:error, "Appointment not found")
          |> redirect(to: ~p"/doctor/appointments")
        end

      {:error, reason} ->
        # Missing required data
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/doctor/appointments/#{appointment_id}/medical_details")
    end
  end

  @doc """
  Processes the diagnosis form submission.
  """
  def record_diagnosis(conn, %{"id" => appointment_id, "diagnosis" => diagnosis}) do
    # Get workflow state from session
    workflow_state =
      get_session(conn, :workflow_state) ||
        %{
          workflow_type: :doctor_flow,
          current_step: :list_appointments
        }

    # Validate diagnosis
    case WorkflowValidator.validate_diagnosis(diagnosis) do
      :ok ->
        # Validate transition
        case WorkflowValidator.validate_transition(workflow_state, :complete_appointment) do
          :ok ->
            # Update workflow state
            workflow_state = %{
              workflow_state
              | current_step: :complete_appointment,
                appointment_id: appointment_id,
                diagnosis: diagnosis
            }

            # Store workflow state in session
            conn = put_session(conn, :workflow_state, workflow_state)

            # Redirect to completion _page
            redirect(conn, to: ~p"/doctor/appointments/#{appointment_id}/complete")

          {:error, reason} ->
            # Invalid transition
            conn
            |> put_flash(:error, reason)
            |> redirect(to: ~p"/doctor/appointments")
        end

      {:error, reason} ->
        # Invalid diagnosis
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/doctor/appointments/#{appointment_id}/diagnosis")
    end
  end

  @doc """
  Shows the _appointment completion _page.
  """
  def complete_appointment_form(conn, %{"id" => appointment_id}) do
    # Get workflow state from session
    workflow_state =
      get_session(conn, :workflow_state) ||
        %{
          workflow_type: :doctor_flow,
          current_step: :list_appointments
        }

    # Validate step data
    case WorkflowValidator.validate_step_data(workflow_state) do
      :ok ->
        # Get _appointment details
        # In a real controller, this would be fetched from the database
        _appointment = get_mock_appointment(appointment_id)

        if _appointment do
          # Render the completion _page
          render(conn, :complete_appointment_form,
            _appointment: _appointment,
            medical_details: workflow_state[:medical_details],
            diagnosis: workflow_state[:diagnosis]
          )
        else
          # Appointment not found
          conn
          |> put_flash(:error, "Appointment not found")
          |> redirect(to: ~p"/doctor/appointments")
        end

      {:error, reason} ->
        # Missing required data
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/doctor/appointments")
    end
  end

  @doc """
  Processes the _appointment completion.
  """
  def complete_appointment(conn, %{"id" => appointment_id}) do
    # Get workflow state from session
    workflow_state =
      get_session(conn, :workflow_state) ||
        %{
          workflow_type: :doctor_flow,
          current_step: :list_appointments
        }

    # Validate transition
    case WorkflowValidator.validate_transition(workflow_state, :completed) do
      :ok ->
        # Update workflow state
        workflow_state = %{
          workflow_state
          | current_step: :completed,
            appointment_id: appointment_id,
            completed_at: DateTime.utc_now()
        }

        # Store workflow state in session
        conn = put_session(conn, :workflow_state, workflow_state)

        # In a real controller, this would update the _appointment in the database

        # Redirect to appointments list with success message
        conn
        |> put_flash(:info, "Appointment completed successfully")
        |> redirect(to: ~p"/doctor/appointments")

      {:error, reason} ->
        # Invalid transition
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/doctor/appointments")
    end
  end

  # Helper functions for mock data

  defp get_mock_appointments do
    [
      %{
        id: "appt-1",
        patient_name: "John Doe",
        date: ~D[2023-06-15],
        time: ~T[09:00:00],
        reason: "Annual checkup"
      },
      %{
        id: "appt-2",
        patient_name: "Jane Smith",
        date: ~D[2023-06-15],
        time: ~T[10:30:00],
        reason: "Flu symptoms"
      },
      %{
        id: "appt-3",
        patient_name: "Bob Johnson",
        date: ~D[2023-06-16],
        time: ~T[14:00:00],
        reason: "Follow-up"
      }
    ]
  end

  defp get_mock_appointment(id) do
    get_mock_appointments()
    |> Enum.find(fn _appointment -> _appointment.id == id end)
  end
end
