defmodule ClinicproWeb.DoctorFlowBypassHTML do
  @moduledoc """
  HTML rendering for the DoctorFlowBypassController.
  
  This module provides the templates for rendering the doctor workflow views
  while bypassing AshAuthentication issues.
  """
  
  use ClinicproWeb, :html
  
  embed_templates "doctor_flow_bypass_html/*"
  
  @doc """
  Renders the appointments list _page.
  """
  attr :appointments, :list, required: true
  
  def list_appointments(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-2xl font-bold mb-6">Your Appointments</h1>
      
      <%= if Enum.empty?(@appointments) do %>
        <div class="bg-gray-100 p-6 rounded-lg">
          <p class="text-gray-700">You have no appointments scheduled.</p>
        </div>
      <% else %>
        <div class="bg-white shadow overflow-hidden rounded-lg">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Patient</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reason</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for _appointment <- @appointments do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    <%= _appointment.patient_name %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <%= Calendar.strftime(_appointment.date, "%B %d, %Y") %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <%= Calendar.strftime(_appointment.time, "%H:%M") %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <%= _appointment.reason %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <a href={~p"/doctor/appointments/#{_appointment.id}"} class="text-indigo-600 hover:text-indigo-900">
                      View
                    </a>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end
  
  @doc """
  Renders the _appointment details _page.
  """
  attr :_appointment, :map, required: true
  
  def access_appointment(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="mb-6">
        <a href={~p"/doctor/appointments"} class="text-indigo-600 hover:text-indigo-900">
          &larr; Back to appointments
        </a>
      </div>
      
      <h1 class="text-2xl font-bold mb-6">Appointment Details</h1>
      
      <div class="bg-white shadow overflow-hidden rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h2 class="text-lg leading-6 font-medium text-gray-900">
            Appointment with <%= @_appointment.patient_name %>
          </h2>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            <%= Calendar.strftime(@_appointment.date, "%B %d, %Y") %> at <%= Calendar.strftime(@_appointment.time, "%H:%M") %>
          </p>
        </div>
        
        <div class="border-t border-gray-200">
          <dl>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Patient name</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @_appointment.patient_name %></dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Date</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= Calendar.strftime(@_appointment.date, "%B %d, %Y") %></dd>
            </div>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Time</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= Calendar.strftime(@_appointment.time, "%H:%M") %></dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Reason for visit</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @_appointment.reason %></dd>
            </div>
          </dl>
        </div>
      </div>
      
      <div class="mt-8">
        <a href={~p"/doctor/appointments/#{@_appointment.id}/medical_details"} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
          Enter Medical Details
        </a>
      </div>
    </div>
    """
  end
  
  @doc """
  Renders the medical details form.
  """
  attr :_appointment, :map, required: true
  
  def fill_medical_details_form(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="mb-6">
        <a href={~p"/doctor/appointments/#{@_appointment.id}"} class="text-indigo-600 hover:text-indigo-900">
          &larr; Back to _appointment details
        </a>
      </div>
      
      <h1 class="text-2xl font-bold mb-6">Enter Medical Details</h1>
      <p class="mb-6 text-gray-600">
        Enter the medical details for <%= @_appointment.patient_name %>'s _appointment.
      </p>
      
      <div class="bg-white shadow overflow-hidden rounded-lg">
        <form action={~p"/doctor/appointments/#{@_appointment.id}/medical_details"} method="post">
          <div class="px-4 py-5 sm:p-6">
            <div class="grid grid-cols-6 gap-6">
              <div class="col-span-6 sm:col-span-3">
                <label for="height" class="block text-sm font-medium text-gray-700">Height (cm)</label>
                <input type="text" name="medical_details[height]" id="height" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md" required />
              </div>
              
              <div class="col-span-6 sm:col-span-3">
                <label for="weight" class="block text-sm font-medium text-gray-700">Weight (kg)</label>
                <input type="text" name="medical_details[weight]" id="weight" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md" required />
              </div>
              
              <div class="col-span-6 sm:col-span-3">
                <label for="blood_pressure" class="block text-sm font-medium text-gray-700">Blood Pressure</label>
                <input type="text" name="medical_details[blood_pressure]" id="blood_pressure" placeholder="e.g. 120/80" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md" required />
              </div>
              
              <div class="col-span-6 sm:col-span-3">
                <label for="temperature" class="block text-sm font-medium text-gray-700">Temperature (°C)</label>
                <input type="text" name="medical_details[temperature]" id="temperature" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md" required />
              </div>
              
              <div class="col-span-6 sm:col-span-3">
                <label for="pulse" class="block text-sm font-medium text-gray-700">Pulse (bpm)</label>
                <input type="text" name="medical_details[pulse]" id="pulse" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md" />
              </div>
              
              <div class="col-span-6">
                <label for="notes" class="block text-sm font-medium text-gray-700">Notes</label>
                <textarea name="medical_details[notes]" id="notes" rows="3" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"></textarea>
              </div>
            </div>
          </div>
          
          <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
            <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Save and Continue
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
  
  @doc """
  Renders the diagnosis form.
  """
  attr :_appointment, :map, required: true
  attr :medical_details, :map, required: true
  
  def record_diagnosis_form(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="mb-6">
        <a href={~p"/doctor/appointments/#{@_appointment.id}/medical_details"} class="text-indigo-600 hover:text-indigo-900">
          &larr; Back to medical details
        </a>
      </div>
      
      <h1 class="text-2xl font-bold mb-6">Record Diagnosis</h1>
      <p class="mb-6 text-gray-600">
        Record your diagnosis for <%= @_appointment.patient_name %>'s _appointment.
      </p>
      
      <div class="bg-white shadow overflow-hidden rounded-lg mb-8">
        <div class="px-4 py-5 sm:px-6">
          <h2 class="text-lg leading-6 font-medium text-gray-900">Medical Details</h2>
        </div>
        
        <div class="border-t border-gray-200">
          <dl>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Height</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["height"] %> cm</dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Weight</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["weight"] %> kg</dd>
            </div>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Blood Pressure</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["blood_pressure"] %></dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Temperature</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["temperature"] %> °C</dd>
            </div>
            <%= if Map.has_key?(@medical_details, "pulse") do %>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">Pulse</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["pulse"] %> bpm</dd>
              </div>
            <% end %>
            <%= if Map.has_key?(@medical_details, "notes") do %>
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">Notes</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["notes"] %></dd>
              </div>
            <% end %>
          </dl>
        </div>
      </div>
      
      <div class="bg-white shadow overflow-hidden rounded-lg">
        <form action={~p"/doctor/appointments/#{@_appointment.id}/diagnosis"} method="post">
          <div class="px-4 py-5 sm:p-6">
            <div class="grid grid-cols-6 gap-6">
              <div class="col-span-6">
                <label for="diagnosis" class="block text-sm font-medium text-gray-700">Diagnosis</label>
                <input type="text" name="diagnosis[diagnosis]" id="diagnosis" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md" required />
              </div>
              
              <div class="col-span-6">
                <label for="treatment" class="block text-sm font-medium text-gray-700">Treatment</label>
                <textarea name="diagnosis[treatment]" id="treatment" rows="3" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md" required></textarea>
              </div>
              
              <div class="col-span-6">
                <label for="prescription" class="block text-sm font-medium text-gray-700">Prescription (if any)</label>
                <textarea name="diagnosis[prescription]" id="prescription" rows="3" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"></textarea>
              </div>
            </div>
          </div>
          
          <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
            <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Save and Continue
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
  
  @doc """
  Renders the _appointment completion _page.
  """
  attr :_appointment, :map, required: true
  attr :medical_details, :map, required: true
  attr :diagnosis, :map, required: true
  
  def complete_appointment_form(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="mb-6">
        <a href={~p"/doctor/appointments/#{@_appointment.id}/diagnosis"} class="text-indigo-600 hover:text-indigo-900">
          &larr; Back to diagnosis
        </a>
      </div>
      
      <h1 class="text-2xl font-bold mb-6">Complete Appointment</h1>
      <p class="mb-6 text-gray-600">
        Review and complete <%= @_appointment.patient_name %>'s _appointment.
      </p>
      
      <div class="bg-white shadow overflow-hidden rounded-lg mb-8">
        <div class="px-4 py-5 sm:px-6">
          <h2 class="text-lg leading-6 font-medium text-gray-900">Appointment Summary</h2>
        </div>
        
        <div class="border-t border-gray-200">
          <dl>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Patient</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @_appointment.patient_name %></dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Date & Time</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <%= Calendar.strftime(@_appointment.date, "%B %d, %Y") %> at <%= Calendar.strftime(@_appointment.time, "%H:%M") %>
              </dd>
            </div>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Reason</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @_appointment.reason %></dd>
            </div>
          </dl>
        </div>
      </div>
      
      <div class="bg-white shadow overflow-hidden rounded-lg mb-8">
        <div class="px-4 py-5 sm:px-6">
          <h2 class="text-lg leading-6 font-medium text-gray-900">Medical Details</h2>
        </div>
        
        <div class="border-t border-gray-200">
          <dl>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Height</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["height"] %> cm</dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Weight</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["weight"] %> kg</dd>
            </div>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Blood Pressure</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["blood_pressure"] %></dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Temperature</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["temperature"] %> °C</dd>
            </div>
            <%= if Map.has_key?(@medical_details, "pulse") do %>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">Pulse</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["pulse"] %> bpm</dd>
              </div>
            <% end %>
            <%= if Map.has_key?(@medical_details, "notes") do %>
              <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">Notes</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @medical_details["notes"] %></dd>
              </div>
            <% end %>
          </dl>
        </div>
      </div>
      
      <div class="bg-white shadow overflow-hidden rounded-lg mb-8">
        <div class="px-4 py-5 sm:px-6">
          <h2 class="text-lg leading-6 font-medium text-gray-900">Diagnosis</h2>
        </div>
        
        <div class="border-t border-gray-200">
          <dl>
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Diagnosis</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @diagnosis["diagnosis"] %></dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Treatment</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @diagnosis["treatment"] %></dd>
            </div>
            <%= if Map.has_key?(@diagnosis, "prescription") do %>
              <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">Prescription</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"><%= @diagnosis["prescription"] %></dd>
              </div>
            <% end %>
          </dl>
        </div>
      </div>
      
      <form action={~p"/doctor/appointments/#{@_appointment.id}/complete"} method="post">
        <div class="flex justify-end">
          <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            Complete Appointment
          </button>
        </div>
      </form>
    </div>
    """
  end
end
