defmodule ClinicproWeb.SearchController do
  use ClinicproWeb, :controller
  alias ClinicproWeb.Plugs.WorkflowValidator
  require Logger

  # Apply the workflow validator plug to all actions in this controller
  plug WorkflowValidator,
       [workflow: :search_flow] when action in [:index, :filters, :results, :detail]

  # Specific step requirements for each action
  plug WorkflowValidator,
       [workflow: :search_flow, required_step: :query_input, redirect_to: "/search"]
       when action in [:filters]

  plug WorkflowValidator,
       [workflow: :search_flow, required_step: :filter_selection, redirect_to: "/search/filters"]
       when action in [:results]

  plug WorkflowValidator,
       [workflow: :search_flow, required_step: :results_display, redirect_to: "/search/results"]
       when action in [:detail]

  @doc """
  Initial search _page with query input.
  """
  def index(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]
    recent_searches = get_session(conn, :recent_searches) || []

    render(conn, :index,
      workflow_state: workflow_state,
      recent_searches: recent_searches
    )
  end

  @doc """
  Process the search query and advance to filters.
  """
  def query_submit(conn, %{"query" => query}) do
    # Validate query
    if String.length(query) < 2 do
      conn
      |> put_flash(:error, "Search query must be at least 2 characters")
      |> redirect(to: ~p"/search")
    else
      # Store query in session
      conn = put_session(conn, :search_query, query)

      # Update recent searches
      recent_searches = get_session(conn, :recent_searches) || []
      updated_searches = [query | recent_searches] |> Enum.uniq() |> Enum.take(5)
      conn = put_session(conn, :recent_searches, updated_searches)

      # Advance the workflow to the next step
      conn = WorkflowValidator.advance_workflow(conn, "user-#{get_session(conn, :user_id)}")

      redirect(conn, to: ~p"/search/filters")
    end
  end

  @doc """
  Show filter options for search.
  """
  def filters(conn, _params) do
    workflow_state = conn.assigns[:workflow_state]
    query = get_session(conn, :search_query)

    # Get filter options
    filter_options = get_filter_options()

    render(conn, :filters,
      workflow_state: workflow_state,
      query: query,
      filter_options: filter_options
    )
  end

  @doc """
  Process filters and advance to results.
  """
  def filters_submit(conn, %{"filters" => filters}) do
    # Store filters in session
    conn = put_session(conn, :search_filters, filters)

    # Advance the workflow to the next step
    conn = WorkflowValidator.advance_workflow(conn, "user-#{get_session(conn, :user_id)}")

    redirect(conn, to: ~p"/search/results")
  end

  @doc """
  Show search results.
  """
  def results(conn, params) do
    workflow_state = conn.assigns[:workflow_state]
    query = get_session(conn, :search_query)
    filters = get_session(conn, :search_filters)

    # Get page from params or default to 1
    page = params["page"] || "1"
    page = String.to_integer(page)

    # Perform search with pagination
    search_results = perform_search(query, filters, page)

    # Log search for analytics
    log_search_metrics(conn, query, filters, search_results.total_count)

    render(conn, :results,
      workflow_state: workflow_state,
      query: query,
      filters: filters,
      results: search_results.results,
      page: page,
      total_count: search_results.total_count,
      page_count: search_results.page_count
    )
  end

  @doc """
  Show detail view of a search result.
  """
  def detail(conn, %{"id" => id}) do
    workflow_state = conn.assigns[:workflow_state]

    # Get the selected item
    case get_item_by_id(id) do
      {:ok, item} ->
        # Track that this result was viewed
        track_result_view(conn, id)

        # Get available actions based on item type
        available_actions = get_available_actions(item)

        # Get related items
        related_items = get_related_items(item)

        render(conn, :detail,
          workflow_state: workflow_state,
          item: item,
          available_actions: available_actions,
          related_items: related_items
        )

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "The requested item could not be found")
        |> redirect(to: ~p"/search/results")
    end
  end

  # Private helpers

  defp get_filter_options do
    # Default filters for all users
    %{
      date_range: ["Today", "This Week", "This Month"],
      appointment_types: ["Consultation", "Follow-up", "Emergency", "Surgery"],
      patient_status: ["New", "Returning", "Urgent"],
      medical_records: ["Available", "Incomplete", "Pending"]
    }
  end

  defp perform_search(_query, _filters, page) do
    # This is a placeholder implementation
    # In a real app, this would query the database

    # Generate mock results
    results =
      Enum.map(((page - 1) * 10 + 1)..(page * 10), fn i ->
        %{
          id: "_appointment-#{i}",
          type: "Appointment",
          patient_name: "Patient #{i}",
          doctor_name: "Dr. Smith",
          date: Date.utc_today() |> Date.add(i),
          status: Enum.random(["Scheduled", "Completed", "Cancelled"]),
          notes: "Medical notes for _appointment #{i}"
        }
      end)

    # Return results with pagination info
    %{
      results: results,
      # Mock total
      total_count: 50,
      # Mock _page count
      page_count: 5
    }
  end

  defp get_item_by_id(id) do
    # This is a placeholder implementation
    # In a real app, this would query the database

    # Mock item data
    {:ok,
     %{
       id: id,
       title: "Item #{id}",
       description: "Detailed information about #{id}",
       date: Date.utc_today(),
       status: "Active",
       details: %{
         created_at: DateTime.utc_now() |> DateTime.add(-86400),
         updated_at: DateTime.utc_now(),
         metadata: %{
           source: "System",
           version: "1.0"
         }
       }
     }}
  end

  defp get_available_actions(_item) do
    # This is a placeholder implementation
    # In a real app, this would check permissions based on user role
    ["view", "edit", "print", "share"]
  end

  defp get_related_items(_item) do
    # This is a placeholder implementation
    # In a real app, this would query related records

    [
      %{id: "related-1", title: "Related Item 1", type: "Appointment"},
      %{id: "related-2", title: "Related Item 2", type: "Medical Record"},
      %{id: "related-3", title: "Related Item 3", type: "Invoice"}
    ]
  end

  defp log_search_metrics(conn, query, filters, total_count) do
    # This is a placeholder implementation
    # In a real app, this would log to a database or analytics service

    user_id = get_session(conn, :user_id)

    Logger.info(
      "Search performed: query=#{query}, filters=#{inspect(filters)}, results=#{total_count}, user=user-#{user_id}"
    )
  end

  defp track_result_view(conn, item_id) do
    # This is a placeholder implementation
    # In a real app, this would log to a database or analytics service

    user_id = get_session(conn, :user_id)
    Logger.info("Search result viewed: item=#{item_id}, user=user-#{user_id}")
  end
end
