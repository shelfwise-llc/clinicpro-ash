defmodule ClinicproWeb.GuestBookingControllerTest do
  use ClinicproWeb.ConnCase

  describe "guest booking flow" do
    test "GET /booking - renders initiate page", %{conn: conn} do
      conn = get(conn, ~p"/booking")
      
      # Should render initiate page
      response = html_response(conn, 200)
      assert response =~ "Book an Appointment"
      assert response =~ "Welcome to ClinicPro"
    end

    test "POST /booking/initiate - starts workflow and redirects to type selection", %{conn: conn} do
      # Make the request to initiate booking
      conn = post(conn, ~p"/booking/initiate", %{})
      
      # Should redirect to type selection page
      assert redirected_to(conn) == ~p"/booking/type"
      
      # Workflow state should be initialized
      assert get_session(conn, :workflow_state).current_step == :select_type
    end

    test "GET /booking/type - renders type selection page", %{conn: conn} do
      # Setup session data
      conn = conn
             |> init_test_session(%{})
             |> put_session(:workflow_state, %{current_step: :select_type})
      
      # Make the request
      conn = get(conn, ~p"/booking/type")
      
      # Should render type selection page
      response = html_response(conn, 200)
      assert response =~ "Select Appointment Type"
      assert response =~ "What type of appointment do you need?"
      
      # Should contain appointment type options
      assert response =~ "Consultation"
      assert response =~ "Follow-up"
      assert response =~ "Physical Exam"
      assert response =~ "Urgent Care"
    end

    test "POST /booking/type - processes type selection and redirects to phone collection", %{conn: conn} do
      # Setup session data
      conn = conn
             |> init_test_session(%{})
             |> put_session(:workflow_state, %{current_step: :select_type})
      
      # Make the request with appointment type
      type_params = %{
        "appointment_type" => "consultation"
      }
      
      conn = post(conn, ~p"/booking/type", type_params)
      
      # Should redirect to phone collection page
      assert redirected_to(conn) == ~p"/booking/phone"
      
      # Session should contain appointment type
      assert get_session(conn, :appointment_type) == "consultation"
      
      # Workflow state should be updated
      assert get_session(conn, :workflow_state).current_step == :collect_phone
    end

    test "GET /booking/phone - renders phone collection page", %{conn: conn} do
      # Setup session data
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_type, "consultation")
             |> put_session(:workflow_state, %{current_step: :collect_phone})
      
      # Make the request
      conn = get(conn, ~p"/booking/phone")
      
      # Should render phone collection page
      response = html_response(conn, 200)
      assert response =~ "Contact Information"
      assert response =~ "Provide your contact details"
      assert response =~ "consultation"
      
      # Should contain form fields
      assert response =~ "Full Name"
      assert response =~ "Email Address"
      assert response =~ "Phone Number"
      assert response =~ "Preferred Date"
    end

    test "POST /booking/phone - processes contact info and redirects to invoice", %{conn: conn} do
      # Setup session data
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_type, "consultation")
             |> put_session(:workflow_state, %{current_step: :collect_phone})
      
      # Make the request with contact info
      contact_params = %{
        "contact" => %{
          "name" => "John Doe",
          "email" => "john@example.com",
          "phone" => "555-123-4567",
          "preferred_date" => "2025-07-25",
          "preferred_time" => "morning",
          "reason" => "Annual checkup",
          "terms_accepted" => "true"
        }
      }
      
      conn = post(conn, ~p"/booking/phone", contact_params)
      
      # Should redirect to invoice page
      assert redirected_to(conn) == ~p"/booking/invoice"
      
      # Session should contain contact info
      assert get_session(conn, :contact_info) != nil
      
      # Workflow state should be updated
      assert get_session(conn, :workflow_state).current_step == :generate_invoice
    end

    test "GET /booking/invoice - renders invoice page", %{conn: conn} do
      # Setup session data
      contact_info = %{
        "name" => "John Doe",
        "email" => "john@example.com",
        "phone" => "555-123-4567",
        "preferred_date" => "2025-07-25",
        "preferred_time" => "morning",
        "reason" => "Annual checkup"
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_type, "consultation")
             |> put_session(:contact_info, contact_info)
             |> put_session(:workflow_state, %{current_step: :generate_invoice})
      
      # Make the request
      conn = get(conn, ~p"/booking/invoice")
      
      # Should render invoice page
      response = html_response(conn, 200)
      assert response =~ "Appointment Summary"
      assert response =~ "John Doe"
      assert response =~ "john@example.com"
      assert response =~ "consultation"
      
      # Should contain payment information
      assert response =~ "Payment Information"
      assert response =~ "Invoice #"
    end

    test "POST /booking/invoice - processes invoice and redirects to confirmation", %{conn: conn} do
      # Setup session data
      contact_info = %{
        "name" => "John Doe",
        "email" => "john@example.com",
        "phone" => "555-123-4567",
        "preferred_date" => "2025-07-25",
        "preferred_time" => "morning",
        "reason" => "Annual checkup"
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_type, "consultation")
             |> put_session(:contact_info, contact_info)
             |> put_session(:invoice_number, "INV-12345")
             |> put_session(:workflow_state, %{current_step: :generate_invoice})
      
      # Make the request to confirm booking
      conn = post(conn, ~p"/booking/invoice", %{})
      
      # Should redirect to confirmation page
      assert redirected_to(conn) == ~p"/booking/confirmation"
      
      # Workflow state should be updated
      assert get_session(conn, :workflow_state).current_step == :confirmation
    end

    test "GET /booking/confirmation - renders confirmation page", %{conn: conn} do
      # Setup session data
      contact_info = %{
        "name" => "John Doe",
        "email" => "john@example.com",
        "phone" => "555-123-4567",
        "preferred_date" => "2025-07-25",
        "preferred_time" => "morning",
        "reason" => "Annual checkup"
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_type, "consultation")
             |> put_session(:contact_info, contact_info)
             |> put_session(:invoice_number, "INV-12345")
             |> put_session(:booking_reference, "BOOK-67890")
             |> put_session(:workflow_state, %{current_step: :confirmation})
      
      # Make the request
      conn = get(conn, ~p"/booking/confirmation")
      
      # Should render confirmation page
      response = html_response(conn, 200)
      assert response =~ "Booking Confirmed"
      assert response =~ "John Doe"
      assert response =~ "john@example.com"
      assert response =~ "BOOK-67890"
      
      # Should contain next steps information
      assert response =~ "What happens next?"
      assert response =~ "Need to make changes?"
    end
  end
end
