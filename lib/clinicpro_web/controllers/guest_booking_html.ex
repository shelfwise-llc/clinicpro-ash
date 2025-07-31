defmodule ClinicproWeb.GuestBookingHTML do
  use ClinicproWeb, :html

  embed_templates "guest_booking_html/*"

  @doc """
  Renders the workflow progress bar.
  """
  attr :workflow_state, :map, required: true
  attr :class, :string, default: ""

  def workflow_progress(assigns) do
    steps = Clinicpro.Appointments.WorkflowTracker.available_workflows()[:guest_booking]
    current_step = assigns[:workflow_state].current_step

    # Find the index of the current step
    current_index = Enum.find_index(steps, fn step -> step == current_step end)

    # Create a new assigns map with the additional values
    assigns = Map.merge(assigns, %{
      steps: steps,
      current_index: current_index
    })

    ~H"""
    <div class={"workflow-progress #{@class}"}>
      <ol class="steps">
        <%= for {step, index} <- Enum.with_index(@steps) do %>
          <li class={"step #{if index <= @current_index, do: "step-primary", else: ""}"}>
            <%= step |> to_string() |> String.replace("_unused", " ") |> String.capitalize() %>
          </li>
        <% end %>
      </ol>
    </div>
    """
  end
end
