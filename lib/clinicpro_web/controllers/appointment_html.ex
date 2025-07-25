defmodule ClinicproWeb.AppointmentHTML do
  use ClinicproWeb, :html

  embed_templates "appointment_html/*"
  
  @doc """
  Renders the _appointment details _page.
  """
  def show(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 class="text-2xl font-bold mb-6 text-gray-800">Appointment Details</h1>
      
      <div class="mb-6 p-4 border rounded-md bg-gray-50">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-semibold">Appointment #<%= @_appointment.id %></h2>
          <span class={appointment_type_badge(@_appointment.appointment_type)}>
            <%= String.capitalize(@_appointment.appointment_type || "Onsite") %>
          </span>
        </div>
        
        <div class="grid grid-cols-2 gap-2">
          <div class="text-gray-600">Date:</div>
          <div><%= format_date(@_appointment.scheduled_date) %></div>
          
          <div class="text-gray-600">Time:</div>
          <div><%= format_time(@_appointment.scheduled_time) %></div>
          
          <div class="text-gray-600">Doctor:</div>
          <div><%= @_appointment.doctor_name %></div>
          
          <div class="text-gray-600">Status:</div>
          <div class={appointment_status_color(@_appointment.status)}>
            <%= String.capitalize(@_appointment.status) %>
          </div>
        </div>
      </div>
      
      <%= if @invoice do %>
        <div class="mb-6 p-4 border rounded-md bg-gray-50">
          <h3 class="text-lg font-semibold mb-2">Payment Information</h3>
          <div class="grid grid-cols-2 gap-2">
            <div class="text-gray-600">Invoice #:</div>
            <div><%= @invoice.reference_number %></div>
            
            <div class="text-gray-600">Amount:</div>
            <div>KES <%= :erlang.float_to_binary(@invoice.amount, decimals: 2) %></div>
            
            <div class="text-gray-600">Status:</div>
            <div class={invoice_status_color(@invoice.status)}>
              <%= String.capitalize(@invoice.status) %>
            </div>
          </div>
          
          <%= if @invoice.status == "unpaid" do %>
            <div class="mt-4">
              <a href={~p"/q/payment/#{@invoice.id}"} class="bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 inline-block">
                Pay Now
              </a>
            </div>
          <% end %>
        </div>
      <% end %>
      
      <div class="flex flex-col space-y-4">
        <%= if @_appointment.appointment_type == "virtual" && @invoice && @invoice.status == "paid" do %>
          <a href={~p"/q/_appointment/virtual/#{@_appointment.id}"} class="bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 text-center">
            Access Virtual Appointment
          </a>
        <% end %>
        
        <%= if @_appointment.appointment_type == "onsite" && @invoice && @invoice.status == "paid" do %>
          <a href={~p"/q/_appointment/onsite/#{@_appointment.id}"} class="bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 text-center">
            View Clinic Details
          </a>
        <% end %>
        
        <a href="/patient/dashboard" class="text-blue-600 hover:underline text-center">
          Back to Dashboard
        </a>
      </div>
    </div>
    """
  end
  
  @doc """
  Renders the virtual _appointment link _page.
  """
  def virtual_link(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 class="text-2xl font-bold mb-6 text-gray-800">Virtual Appointment</h1>
      
      <div class="mb-6 p-4 border rounded-md bg-gray-50">
        <h2 class="text-lg font-semibold mb-4">Appointment Details</h2>
        <div class="grid grid-cols-2 gap-2">
          <div class="text-gray-600">Date:</div>
          <div><%= format_date(@_appointment.scheduled_date) %></div>
          
          <div class="text-gray-600">Time:</div>
          <div><%= format_time(@_appointment.scheduled_time) %></div>
          
          <div class="text-gray-600">Doctor:</div>
          <div><%= @_appointment.doctor_name %></div>
        </div>
      </div>
      
      <div class="mb-6 p-4 border-2 border-green-500 rounded-md bg-green-50">
        <h3 class="text-lg font-semibold mb-2 text-green-700">Your Virtual Meeting Link</h3>
        <p class="mb-4 text-sm text-gray-600">
          Click the button below to join your virtual _appointment. Please join 5 minutes before your scheduled time.
        </p>
        
        <div class="flex flex-col space-y-4">
          <a href={@meeting_link} target="_blank" rel="noopener noreferrer" class="bg-green-600 text-white py-3 px-4 rounded-md hover:bg-green-700 text-center font-semibold">
            Join Virtual Appointment
          </a>
          
          <div class="text-sm text-gray-500 break-all">
            <span class="font-semibold">Link:</span> <%= @meeting_link %>
          </div>
        </div>
      </div>
      
      <div class="mb-6 p-4 border rounded-md bg-blue-50">
        <h3 class="text-lg font-semibold mb-2 text-blue-700">Preparation Tips</h3>
        <ul class="list-disc pl-5 space-y-2 text-sm">
          <li>Ensure you have a stable internet connection</li>
          <li>Find a quiet, private space for your _appointment</li>
          <li>Test your camera and microphone before joining</li>
          <li>Have any relevant medical documents or information ready</li>
          <li>Write down any questions you want to ask the doctor</li>
        </ul>
      </div>
      
      <div class="flex flex-col space-y-4">
        <a href={~p"/q/_appointment/#{@_appointment.id}"} class="text-blue-600 hover:underline text-center">
          Back to Appointment Details
        </a>
      </div>
    </div>
    """
  end
  
  @doc """
  Renders the onsite _appointment details _page.
  """
  def onsite_details(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 class="text-2xl font-bold mb-6 text-gray-800">Onsite Appointment</h1>
      
      <div class="mb-6 p-4 border rounded-md bg-gray-50">
        <h2 class="text-lg font-semibold mb-4">Appointment Details</h2>
        <div class="grid grid-cols-2 gap-2">
          <div class="text-gray-600">Date:</div>
          <div><%= format_date(@_appointment.scheduled_date) %></div>
          
          <div class="text-gray-600">Time:</div>
          <div><%= format_time(@_appointment.scheduled_time) %></div>
          
          <div class="text-gray-600">Doctor:</div>
          <div><%= @_appointment.doctor_name %></div>
        </div>
      </div>
      
      <div class="mb-6 p-4 border-2 border-blue-500 rounded-md bg-blue-50">
        <h3 class="text-lg font-semibold mb-2 text-blue-700">Clinic Information</h3>
        
        <div class="grid grid-cols-2 gap-2">
          <div class="text-gray-600">Clinic Name:</div>
          <div><%= @clinic.name %></div>
          
          <div class="text-gray-600">Address:</div>
          <div><%= @clinic.address %></div>
          
          <div class="text-gray-600">Phone:</div>
          <div><%= @clinic.phone %></div>
          
          <div class="text-gray-600">Email:</div>
          <div><%= @clinic.email %></div>
        </div>
        
        <div class="mt-4">
          <h4 class="font-semibold text-gray-700">Directions:</h4>
          <p class="text-sm text-gray-600"><%= @clinic.directions %></p>
        </div>
      </div>
      
      <div class="mb-6 p-4 border rounded-md bg-yellow-50">
        <h3 class="text-lg font-semibold mb-2 text-yellow-700">What to Bring</h3>
        <ul class="list-disc pl-5 space-y-2 text-sm">
          <li>Your ID or passport</li>
          <li>Insurance card (if applicable)</li>
          <li>List of current medications</li>
          <li>Any relevant medical records or test results</li>
          <li>Payment method (if additional services are required)</li>
        </ul>
      </div>
      
      <div class="flex flex-col space-y-4">
        <a href={~p"/q/_appointment/#{@_appointment.id}"} class="text-blue-600 hover:underline text-center">
          Back to Appointment Details
        </a>
      </div>
    </div>
    """
  end
  
  # Helper functions
  
  defp format_date(date) do
    case date do
      %Date{} -> Calendar.strftime(date, "%B %d, %Y")
      _ -> "Not scheduled"
    end
  end
  
  defp format_time(time) do
    case time do
      %Time{} -> Calendar.strftime(time, "%I:%M %p")
      _ -> "Not scheduled"
    end
  end
  
  defp appointment_status_color(status) do
    case status do
      "confirmed" -> "text-green-600 font-semibold"
      "pending" -> "text-yellow-600 font-semibold"
      "cancelled" -> "text-red-600 font-semibold"
      "completed" -> "text-blue-600 font-semibold"
      _ -> "text-gray-600"
    end
  end
  
  defp invoice_status_color(status) do
    case status do
      "paid" -> "text-green-600 font-semibold"
      "pending" -> "text-yellow-600 font-semibold"
      "unpaid" -> "text-red-600 font-semibold"
      _ -> "text-gray-600"
    end
  end
  
  defp appointment_type_badge(type) do
    case type do
      "virtual" -> "bg-blue-100 text-blue-800 px-2 py-1 rounded-full text-xs font-semibold"
      "onsite" -> "bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-semibold"
      "walk_in" -> "bg-purple-100 text-purple-800 px-2 py-1 rounded-full text-xs font-semibold"
      _ -> "bg-gray-100 text-gray-800 px-2 py-1 rounded-full text-xs font-semibold"
    end
  end
end
