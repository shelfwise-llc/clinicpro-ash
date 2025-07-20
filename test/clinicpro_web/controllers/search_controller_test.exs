defmodule ClinicproWeb.SearchControllerTest do
  use ClinicproWeb.ConnCase

  describe "search flow" do
    test "GET /search - renders search form", %{conn: conn} do
      conn = get(conn, ~p"/search")
      
      # Should render search form
      response = html_response(conn, 200)
      assert response =~ "Search"
      assert response =~ "What are you looking for?"
    end

    test "POST /search - processes search query and redirects to filters", %{conn: conn} do
      # Make the request with search query
      search_params = %{
        "query" => "diabetes"
      }
      
      conn = post(conn, ~p"/search", search_params)
      
      # Should redirect to filters page
      assert redirected_to(conn) == ~p"/search/filters"
      
      # Session should contain search query
      assert get_session(conn, :search_query) == "diabetes"
      
      # Workflow state should be updated
      assert get_session(conn, :workflow_state).current_step == :filters
    end

    test "GET /search/filters - renders filters page", %{conn: conn} do
      # Setup session data
      conn = conn
             |> init_test_session(%{})
             |> put_session(:search_query, "diabetes")
             |> put_session(:workflow_state, %{current_step: :filters})
      
      # Make the request
      conn = get(conn, ~p"/search/filters")
      
      # Should render filters page
      response = html_response(conn, 200)
      assert response =~ "Search Filters"
      assert response =~ "diabetes"
      
      # Should contain filter options
      assert response =~ "Date Range"
      assert response =~ "Appointment Types"
    end

    test "POST /search/filters - processes filters and redirects to results", %{conn: conn} do
      # Setup session data
      conn = conn
             |> init_test_session(%{})
             |> put_session(:search_query, "diabetes")
             |> put_session(:workflow_state, %{current_step: :filters})
      
      # Make the request with filter data
      filter_params = %{
        "filters" => %{
          "date_range" => "Last 30 days",
          "appointment_types" => ["Consultation", "Follow-up"],
          "patient_status" => ["Active"]
        }
      }
      
      conn = post(conn, ~p"/search/filters", filter_params)
      
      # Should redirect to results page
      assert redirected_to(conn) == ~p"/search/results"
      
      # Session should contain filter data
      assert get_session(conn, :search_filters) != nil
      
      # Workflow state should be updated
      assert get_session(conn, :workflow_state).current_step == :results
    end

    test "GET /search/results - renders results page", %{conn: conn} do
      # Setup session data
      search_filters = %{
        "date_range" => "Last 30 days",
        "appointment_types" => ["Consultation", "Follow-up"],
        "patient_status" => ["Active"]
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:search_query, "diabetes")
             |> put_session(:search_filters, search_filters)
             |> put_session(:workflow_state, %{current_step: :results})
      
      # Make the request
      conn = get(conn, ~p"/search/results")
      
      # Should render results page
      response = html_response(conn, 200)
      assert response =~ "Search Results"
      assert response =~ "diabetes"
      
      # Should show applied filters
      assert response =~ "Last 30 days"
      
      # Should contain results table
      assert response =~ "Patient"
      assert response =~ "Doctor"
      assert response =~ "Date"
    end

    test "GET /search/detail/:id - renders detail page", %{conn: conn} do
      # Setup session data
      search_filters = %{
        "date_range" => "Last 30 days",
        "appointment_types" => ["Consultation", "Follow-up"],
        "patient_status" => ["Active"]
      }
      
      conn = conn
             |> init_test_session(%{})
             |> put_session(:search_query, "diabetes")
             |> put_session(:search_filters, search_filters)
             |> put_session(:workflow_state, %{current_step: :detail})
      
      # Make the request
      item_id = "item-123"
      conn = get(conn, ~p"/search/detail/#{item_id}")
      
      # Should render detail page
      response = html_response(conn, 200)
      assert response =~ "Item Details"
      
      # Should contain item details
      assert response =~ "Description"
      assert response =~ "Details"
    end
  end
end
