defmodule ClinicproWeb.PatientFlowControllerTest do
  use ClinicproWeb.ConnCase

  describe "patient flow" do
    test "GET /patient/receive-link/:token - validates token and redirects to welcome", %{conn: conn} do
      # Create a mock token
      token = "valid-test-token-123"
      
      # Make the request
      conn = get(conn, ~p"/patient/receive-link/#{token}")
      
      # Should redirect to welcome page
      assert redirected_to(conn) == ~p"/patient/welcome"
      
      # Session should contain appointment data and token
      assert get_session(conn, :appointment_data) != nil
      assert get_session(conn, :patient_token) == token
    end

    test "GET /patient/receive-link/:token - handles invalid token", %{conn: conn} do
      # Create an invalid mock token
      token = "invalid-token"
      
      # Make the request
      conn = get(conn, ~p"/patient/receive-link/#{token}")
      
      # Should redirect to error page or home
      assert redirected_to(conn) == ~p"/"
      assert get_flash(conn, :error) =~ "Invalid or expired token"
    end

    test "GET /patient/welcome - renders welcome page with appointment data", %{conn: conn} do
      # Setup session data
      appointment_data = %{
        "id" => "123",
        "doctor" => "Dr. Smith",
        "date" => "2025-07-25",
        "time" => "10:00 AM",
        "type" => "Consultation"
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_data, appointment_data)
             |> put_session(:patient_token, "valid-test-token-123")
             |> put_session(:workflow_state, %{current_step: :welcome})
      
      # Make the request
      conn = get(conn, ~p"/patient/welcome")
      
      # Should render welcome page with appointment data
      response = html_response(conn, 200)
      assert response =~ "Welcome"
      assert response =~ "Dr. Smith"
      assert response =~ "2025-07-25"
    end

    test "GET /patient/confirm-details - renders confirmation page", %{conn: conn} do
      # Setup session data
      appointment_data = %{
        "id" => "123",
        "doctor" => "Dr. Smith",
        "date" => "2025-07-25",
        "time" => "10:00 AM",
        "type" => "Consultation"
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_data, appointment_data)
             |> put_session(:patient_token, "valid-test-token-123")
             |> put_session(:workflow_state, %{current_step: :confirm_details})
      
      # Make the request
      conn = get(conn, ~p"/patient/confirm-details")
      
      # Should render confirmation page
      response = html_response(conn, 200)
      assert response =~ "Confirm Your Details"
      assert response =~ "Dr. Smith"
    end

    test "POST /patient/confirm-details - processes confirmation and advances workflow", %{conn: conn} do
      # Setup session data
      appointment_data = %{
        "id" => "123",
        "doctor" => "Dr. Smith",
        "date" => "2025-07-25",
        "time" => "10:00 AM",
        "type" => "Consultation"
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_data, appointment_data)
             |> put_session(:patient_token, "valid-test-token-123")
             |> put_session(:workflow_state, %{current_step: :confirm_details})
      
      # Make the request with confirmation data
      confirmation_params = %{
        "confirmation" => %{
          "name" => "John Doe",
          "email" => "john@example.com",
          "phone" => "555-123-4567",
          "special_needs" => "None"
        }
      }
      
      conn = post(conn, ~p"/patient/confirm-details", confirmation_params)
      
      # Should redirect to booking confirmation
      assert redirected_to(conn) == ~p"/patient/booking-confirmation"
      
      # Session should contain confirmation data
      assert get_session(conn, :confirmation_details) != nil
    end

    test "GET /patient/booking-confirmation - renders booking confirmation page", %{conn: conn} do
      # Setup session data
      appointment_data = %{
        "id" => "123",
        "doctor" => "Dr. Smith",
        "date" => "2025-07-25",
        "time" => "10:00 AM",
        "type" => "Consultation"
      }
      
      confirmation_details = %{
        "name" => "John Doe",
        "email" => "john@example.com",
        "phone" => "555-123-4567",
        "special_needs" => "None"
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:appointment_data, appointment_data)
             |> put_session(:confirmation_details, confirmation_details)
             |> put_session(:patient_token, "valid-test-token-123")
             |> put_session(:workflow_state, %{current_step: :booking_confirmation})
      
      # Make the request
      conn = get(conn, ~p"/patient/booking-confirmation")
      
      # Should render booking confirmation page
      response = html_response(conn, 200)
      assert response =~ "Booking Confirmation"
      assert response =~ "John Doe"
      assert response =~ "Dr. Smith"
    end
  end
end
