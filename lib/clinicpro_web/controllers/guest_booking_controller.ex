defmodule ClinicproWeb.GuestBookingController do
  use ClinicproWeb, :controller
  alias ClinicproWeb.Plugs.WorkflowValidator

  # Apply the workflow validator plug to all actions in this controller
  plug WorkflowValidator,
       [workflow: :guest_booking] when action in [:index, :type, :phone, :invoice, :profile]

  # Specific step requirements for each action
  plug WorkflowValidator,
       [workflow: :guest_booking, required_step: :initiate, redirect_to: "/booking"]
       when action in [:type]

  plug WorkflowValidator,
       [workflow: :guest_booking, required_step: :select_type, redirect_to: "/booking/type"]
       when action in [:phone]

  plug WorkflowValidator,
       [
         workflow: :guest_booking,
         required_step: :collect_phone,
         redirect_to: "/booking/phone"
       ]
       when action in [:invoice]

  plug WorkflowValidator,
       [
         workflow: :guest_booking,
         required_step: :review_invoice,
         redirect_to: "/booking/invoice"
       ]
       when action in [:profile]

  @doc """
  Start the guest booking process.
  """
  def index(conn, _params) do
    # For guest users, we'll use a temporary ID if not already set
    user_id = get_session(conn, :user_id) || "guest-#{System.unique_integer([:positive])}"
    
    # Store the user_id in session for subsequent steps
    conn = put_session(conn, :user_id, user_id)
    
    # Get the workflow state from the connection
    workflow_state = conn.assigns[:workflow_state]
    
    IO.inspect(workflow_state, label: "WORKFLOW STATE IN CONTROLLER")

    conn
    |> put_layout(html: {ClinicproWeb.Layouts, :clinicpro})
    |> assign(:page_title, "Book an Appointment")
    |> assign(:workflow_state, workflow_state)
    |> render(:initiate)
  end

  @doc """
  Initiate the guest booking process (POST handler for the start button).
  """
  def initiate(conn, _params) do
    # For guest users, we'll use a temporary ID if not already set
    user_id = get_session(conn, :user_id) || "guest-#{System.unique_integer([:positive])}"
    
    # Store the user_id in session for subsequent steps
    conn = put_session(conn, :user_id, user_id)
    
    # Advance the workflow to the next step (select_type)
    conn = WorkflowValidator.advance_workflow(conn, user_id, &Clinicpro.Appointments.WorkflowTracker.available_workflows/0)

    # Redirect to the next step (type selection)
    redirect(conn, to: ~p"/booking/type")
  end

  @doc """
  Handle the appointment type selection step.
  """
  def type(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]

    render(conn, :type, workflow_state: workflow_state)
  end

  @doc """
  Process the selected appointment type and advance to the next step.
  """
  def type_submit(conn, %{"type" => appointment_type}) do
    # Store the appointment type in the session
    conn = put_session(conn, :appointment_type, appointment_type)

    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "user-#{get_session(conn, :user_id)}")

    # Redirect to the next step
    redirect(conn, to: ~p"/guest_booking/phone")
  end

  @doc """
  Handle the phone collection step.
  """
  def phone(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]

    render(conn, :phone, workflow_state: workflow_state)
  end

  @doc """
  Process the phone number and advance to the next step.
  """
  def phone_submit(conn, %{"phone" => phone_number}) do
    # Store the phone number in the session
    conn = put_session(conn, :phone_number, phone_number)

    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "user-#{get_session(conn, :user_id)}")

    # Redirect to the next step
    redirect(conn, to: ~p"/guest_booking/invoice")
  end

  @doc """
  Handle the invoice generation step.
  """
  def invoice(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]

    # In a real application, we would generate an actual invoice here
    # For now, we'll just simulate it
    invoice_data = %{
      id: "INV-#{System.unique_integer([:positive])}",
      amount: 100.00,
      appointment_type: get_session(conn, :appointment_type),
      phone: get_session(conn, :phone_number)
    }

    render(conn, :invoice, workflow_state: workflow_state, invoice: invoice_data)
  end

  @doc """
  Process the invoice and advance to the next step.
  """
  def invoice_submit(conn, %{"invoice_id" => invoice_id}) do
    # Store the invoice ID in the session
    conn = put_session(conn, :invoice_id, invoice_id)

    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "user-#{get_session(conn, :user_id)}")

    # Redirect to the next step
    redirect(conn, to: ~p"/guest_booking/profile")
  end

  @doc """
  Handle the profile creation step.
  """
  def profile(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]

    render(conn, :profile, workflow_state: workflow_state)
  end

  @doc """
  Process the profile creation and complete the workflow.
  """
  def profile_submit(conn, %{"name" => name, "email" => email}) do
    # In a real application, we would create a user profile here
    # For now, we'll just simulate it

    # Get all the data from the session
    appointment_type = get_session(conn, :appointment_type)
    phone_number = get_session(conn, :phone_number)
    invoice_id = get_session(conn, :invoice_id)

    # Create a summary of the booking
    booking_summary = %{
      name: name,
      email: email,
      phone: phone_number,
      appointment_type: appointment_type,
      invoice_id: invoice_id,
      appointment_id: get_session(conn, :appointment_id)
    }

    # Store the booking summary in the session
    conn = put_session(conn, :booking_summary, booking_summary)

    # Advance the workflow to the final step
    conn = WorkflowValidator.advance_workflow(conn, "user-#{get_session(conn, :user_id)}")

    # Redirect to the completion page
    redirect(conn, to: ~p"/guest_booking/complete")
  end

  @doc """
  Show the booking completion page.
  """
  def complete(conn, _params) do
    booking_summary = get_session(conn, :booking_summary)

    render(conn, :complete, booking_summary: booking_summary)
  end
end
