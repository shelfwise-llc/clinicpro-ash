defmodule ClinicproWeb.MedicationSearchComponent do
  use ClinicproWeb, :live_component

  # alias Clinicpro.Medications - removed unused alias

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       query: "",
       results: [],
       selected_medication: nil,
       loading: false,
       debounce: 300
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:id, assigns.id || "medication-search")
     |> assign(:clinic_id, assigns.clinic_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <div class="relative">
        <input
          type="text"
          id={"#{@id}-input"}
          name={@name}
          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          placeholder="Search for medications..."
          value={@query}
          phx-target={@myself}
          phx-keyup="search"
          phx-debounce={@debounce}
          autocomplete="off"
          aria-autocomplete="list"
          aria-controls={"#{@id}-results"}
          aria-expanded={length(@results) > 0}
          phx-hook="MedicationSearch"
          data-selected-value={if @selected_medication, do: @selected_medication["name"], else: ""}
          data-selected-id={if @selected_medication, do: @selected_medication["id"], else: ""}
        />

        <input
          type="hidden"
          name={@field_name}
          value={if @selected_medication, do: @selected_medication["id"], else: ""}
        />

        <%= if @loading do %>
          <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
            <svg
              class="animate-spin h-5 w-5 text-gray-400"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              >
              </path>
            </svg>
          </div>
        <% end %>
      </div>

      <%= if length(@results) > 0 do %>
        <div
          id={"#{@id}-results"}
          class="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm"
          role="listbox"
        >
          <%= for medication <- @results do %>
            <div
              class="relative cursor-pointer select-none py-2 pl-3 pr-9 hover:bg-indigo-100"
              role="option"
              phx-click="select"
              phx-value-id={medication["id"]}
              phx-target={@myself}
            >
              <div class="flex items-center">
                <span class="font-medium block truncate"><%= medication["name"] %></span>
              </div>
              <div class="text-xs text-gray-500 mt-1">
                <%= if medication["form"] do %>
                  <span class="mr-2"><%= medication["form"] %></span>
                <% end %>
                <%= if medication["strength"] do %>
                  <span><%= medication["strength"] %></span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <%= if @selected_medication do %>
        <div class="mt-2 p-2 border rounded-md bg-gray-50">
          <div class="flex justify-between">
            <div>
              <div class="font-medium"><%= @selected_medication["name"] %></div>
              <div class="text-sm text-gray-500">
                <%= if @selected_medication["form"] do %>
                  <span class="mr-2"><%= @selected_medication["form"] %></span>
                <% end %>
                <%= if @selected_medication["strength"] do %>
                  <span><%= @selected_medication["strength"] %></span>
                <% end %>
              </div>
            </div>
            <button
              type="button"
              class="text-gray-400 hover:text-gray-500"
              phx-click="clear"
              phx-target={@myself}
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    if String.length(query) >= 2 do
      send(self(), {:search_medications, query, socket.assigns.clinic_id, self()})

      {:noreply, assign(socket, query: query, loading: true)}
    else
      {:noreply, assign(socket, query: query, results: [], loading: false)}
    end
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.results, fn med -> med["id"] == id end)

    {:noreply,
     assign(socket,
       selected_medication: selected,
       query: selected["name"],
       results: []
     )}
  end

  @impl true
  def handle_event("clear", _unused, socket) do
    {:noreply,
     assign(socket,
       selected_medication: nil,
       query: ""
     )}
  end

  @impl true
  def handle_info({:search_results, results}, socket) do
    {:noreply, assign(socket, results: results, loading: false)}
  end
end
