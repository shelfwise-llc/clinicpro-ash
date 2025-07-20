defmodule ClinicproWeb.Plugs.WorkflowValidator do
  @moduledoc """
  Plug for validating workflow state and ensuring users follow the correct steps.
  """
  import Plug.Conn
  import Phoenix.Controller
  alias Clinicpro.Appointments.WorkflowTracker

  def init(opts) do
    # Set default options
    %{
      workflow: opts[:workflow],
      required_step: opts[:required_step],
      redirect_to: opts[:redirect_to] || "/"
    }
  end

  def call(conn, opts) do
    # Get current workflow state from session or initialize it
    workflow_state = get_session(conn, :workflow_state) || init_workflow_state(opts[:workflow])
    
    # Assign workflow state to conn for use in templates
    conn = assign(conn, :workflow_state, workflow_state)
    
    # Store workflow state in session
    conn = put_session(conn, :workflow_state, workflow_state)
    
    # If a specific step is required, validate that the current step matches
    if opts[:required_step] && workflow_state.current_step != opts[:required_step] do
      conn
      |> put_flash(:error, "Please complete the previous step first.")
      |> redirect(to: opts[:redirect_to])
      |> halt()
    else
      conn
    end
  end

  @doc """
  Initialize a new workflow state for the given workflow type.
  """
  def init_workflow(conn, workflow_type, identifier \\ nil) do
    workflow_state = %{
      workflow_type: workflow_type,
      current_step: get_first_step(workflow_type),
      identifier: identifier,
      started_at: DateTime.utc_now()
    }
    
    conn
    |> assign(:workflow_state, workflow_state)
    |> put_session(:workflow_state, workflow_state)
  end

  @doc """
  Advance the workflow to the next step.
  """
  def advance_workflow(conn, _user_id, get_workflow_steps_fn \\ &WorkflowTracker.available_workflows/0) do
    workflow_state = get_session(conn, :workflow_state)
    workflow_type = workflow_state.workflow_type
    
    # Get the steps for this workflow
    steps = get_workflow_steps_fn.()[workflow_type]
    
    # Find the current step index
    current_index = Enum.find_index(steps, &(&1 == workflow_state.current_step))
    
    # Calculate the next step (or stay at the last step)
    next_index = min(current_index + 1, length(steps) - 1)
    next_step = Enum.at(steps, next_index)
    
    # Update the workflow state
    updated_state = Map.put(workflow_state, :current_step, next_step)
    
    # Store the updated state in session
    put_session(conn, :workflow_state, updated_state)
  end

  # Private helpers

  defp init_workflow_state(workflow_type) do
    %{
      workflow_type: workflow_type,
      current_step: get_first_step(workflow_type),
      started_at: DateTime.utc_now()
    }
  end

  defp get_first_step(workflow_type) do
    # Get the first step for the given workflow type
    # This is a simplified implementation for testing
    case workflow_type do
      :patient_flow -> :receive_link
      :doctor_flow -> :list_appointments
      :guest_booking -> :initiate
      :search -> :search
      _ -> :start
    end
  end
end