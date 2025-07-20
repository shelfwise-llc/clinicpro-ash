defmodule ClinicproWeb.Plugs.WorkflowValidatorTest do
  use ClinicproWeb.ConnCase
  alias ClinicproWeb.Plugs.WorkflowValidator
  alias Clinicpro.Appointments.WorkflowTracker

  describe "init/1" do
    test "returns options with defaults" do
      opts = WorkflowValidator.init([workflow: :guest_booking])
      assert opts[:workflow] == :guest_booking
      assert opts[:required_step] == nil
      assert opts[:redirect_to] == "/"
    end

    test "returns options with custom values" do
      opts = WorkflowValidator.init([
        workflow: :patient_flow,
        required_step: :confirm_details,
        redirect_to: "/patient/welcome"
      ])
      
      assert opts[:workflow] == :patient_flow
      assert opts[:required_step] == :confirm_details
      assert opts[:redirect_to] == "/patient/welcome"
    end
  end

  describe "call/2" do
    test "allows request when no required step is specified", %{conn: conn} do
      # Setup session with workflow state
      workflow_state = %{current_step: :welcome}
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:workflow_state, workflow_state)
      
      opts = WorkflowValidator.init([workflow: :patient_flow])
      
      # Call the plug
      conn = WorkflowValidator.call(conn, opts)
      
      # Should assign workflow state to conn
      assert conn.assigns[:workflow_state] == workflow_state
      
      # Should not redirect
      refute conn.halted
    end

    test "allows request when current step matches required step", %{conn: conn} do
      # Setup session with workflow state
      workflow_state = %{current_step: :confirm_details}
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:workflow_state, workflow_state)
      
      opts = WorkflowValidator.init([
        workflow: :patient_flow,
        required_step: :confirm_details
      ])
      
      # Call the plug
      conn = WorkflowValidator.call(conn, opts)
      
      # Should assign workflow state to conn
      assert conn.assigns[:workflow_state] == workflow_state
      
      # Should not redirect
      refute conn.halted
    end

    test "redirects when current step doesn't match required step", %{conn: conn} do
      # Setup session with workflow state
      workflow_state = %{current_step: :welcome}
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:workflow_state, workflow_state)
      
      opts = WorkflowValidator.init([
        workflow: :patient_flow,
        required_step: :confirm_details,
        redirect_to: "/patient/welcome"
      ])
      
      # Call the plug
      conn = WorkflowValidator.call(conn, opts)
      
      # Should redirect
      assert conn.halted
      assert redirected_to(conn) == "/patient/welcome"
      assert get_flash(conn, :error) =~ "complete the previous step"
    end

    test "initializes workflow state when none exists", %{conn: conn} do
      conn = conn
             |> init_test_session(%{})
      
      opts = WorkflowValidator.init([workflow: :guest_booking])
      
      # Call the plug
      conn = WorkflowValidator.call(conn, opts)
      
      # Should initialize workflow state
      assert conn.assigns[:workflow_state] != nil
      assert get_session(conn, :workflow_state) != nil
      
      # Should set current step to first step in workflow
      first_step = WorkflowTracker.available_workflows()[:guest_booking] |> List.first()
      assert conn.assigns[:workflow_state].current_step == first_step
    end
  end

  describe "advance_workflow/2" do
    test "advances workflow to next step", %{conn: conn} do
      # Setup workflow with known steps
      workflow = :patient_flow
      steps = [:receive_link, :welcome, :confirm_details, :booking_confirmation]
      
      # Mock the WorkflowTracker to return our steps
      expect_workflow_steps = fn ->
        %{patient_flow: steps}
      end
      
      # Setup session with current step as first step
      workflow_state = %{current_step: :receive_link}
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:workflow_state, workflow_state)
      
      # Call advance_workflow
      conn = WorkflowValidator.advance_workflow(conn, "user-123", expect_workflow_steps)
      
      # Should advance to next step
      assert get_session(conn, :workflow_state).current_step == :welcome
    end

    test "stays at last step when already at end of workflow", %{conn: conn} do
      # Setup workflow with known steps
      workflow = :patient_flow
      steps = [:receive_link, :welcome, :confirm_details, :booking_confirmation]
      
      # Mock the WorkflowTracker to return our steps
      expect_workflow_steps = fn ->
        %{patient_flow: steps}
      end
      
      # Setup session with current step as last step
      workflow_state = %{current_step: :booking_confirmation}
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:workflow_state, workflow_state)
      
      # Call advance_workflow
      conn = WorkflowValidator.advance_workflow(conn, "user-123", expect_workflow_steps)
      
      # Should stay at last step
      assert get_session(conn, :workflow_state).current_step == :booking_confirmation
    end
  end
end
