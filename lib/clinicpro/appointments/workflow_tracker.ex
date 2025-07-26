defmodule Clinicpro.Appointments.WorkflowTracker do
  @moduledoc """
  Tracks and manages workflow states for different _appointment flows.
  """

  @doc """
  Returns a map of available workflows and their steps.
  """
  def available_workflows do
    %{
      patient_flow: [
        :receive_link,
        :welcome,
        :confirm_details,
        :booking_confirmation
      ],
      doctor_flow: [
        :list_appointments,
        :access_appointment,
        :fill_medical_details,
        :record_diagnosis,
        :save_to_profile
      ],
      guest_booking: [
        :initiate,
        :select_type,
        :collect_phone,
        :generate_invoice,
        :confirmation
      ],
      search: [
        :search,
        :filters,
        :results,
        :detail
      ]
    }
  end

  @doc """
  Gets the current step for a workflow.
  """
  def get_current_step(workflow_state) do
    workflow_state.current_step
  end

  @doc """
  Gets the next step for a workflow.
  """
  def get_next_step(workflow_type, current_step) do
    steps = available_workflows()[workflow_type]
    current_index = Enum.find_index(steps, &(&1 == current_step))

    if current_index < length(steps) - 1 do
      Enum.at(steps, current_index + 1)
    else
      current_step
    end
  end

  @doc """
  Gets the previous step for a workflow.
  """
  def get_previous_step(workflow_type, current_step) do
    steps = available_workflows()[workflow_type]
    current_index = Enum.find_index(steps, &(&1 == current_step))

    if current_index > 0 do
      Enum.at(steps, current_index - 1)
    else
      current_step
    end
  end

  @doc """
  Gets the progress percentage for a workflow.
  """
  def get_progress_percentage(workflow_type, current_step) do
    steps = available_workflows()[workflow_type]
    current_index = Enum.find_index(steps, &(&1 == current_step))

    if current_index do
      trunc(current_index / (length(steps) - 1) * 100)
    else
      0
    end
  end
end
