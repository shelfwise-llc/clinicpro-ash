defmodule ClinicproWeb.AppointmentController do
  use ClinicproWeb, :controller
  
  alias Clinicpro.Appointments
  alias Clinicpro.Invoices
  
  @doc """
  Show appointment details.
  """
  def show(conn, %{"id" => id}) do
    # Get the current patient from the session
    patient = conn.assigns.current_patient
    
    case Appointments.get_appointment(id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found.")
        |> redirect(to: ~p"/patient/dashboard")
        
      appointment ->
        # Check if the appointment belongs to the current patient
        if appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_by_appointment(appointment.id)
          
          render(conn, :show, appointment: appointment, invoice: invoice)
        else
          conn
          |> put_flash(:error, "You don't have permission to view this appointment.")
          |> redirect(to: ~p"/patient/dashboard")
        end
    end
  end
  
  @doc """
  Show virtual appointment link.
  Only available for paid virtual appointments.
  """
  def virtual_link(conn, %{"id" => id}) do
    # Get the current patient from the session
    patient = conn.assigns.current_patient
    
    case Appointments.get_appointment(id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found.")
        |> redirect(to: ~p"/patient/dashboard")
        
      appointment ->
        # Check if the appointment belongs to the current patient
        if appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_by_appointment(appointment.id)
          
          # Check if this is a virtual appointment and payment is complete
          if appointment.appointment_type == "virtual" && invoice && invoice.status == "paid" do
            # Generate or retrieve virtual meeting link
            meeting_link = get_or_generate_meeting_link(appointment)
            
            render(conn, :virtual_link, appointment: appointment, meeting_link: meeting_link)
          else
            conn
            |> put_flash(:error, "Virtual link is only available for paid virtual appointments.")
            |> redirect(to: ~p"/q/appointment/#{appointment.id}")
          end
        else
          conn
          |> put_flash(:error, "You don't have permission to view this appointment.")
          |> redirect(to: ~p"/patient/dashboard")
        end
    end
  end
  
  @doc """
  Show onsite appointment details.
  Only available for paid onsite appointments.
  """
  def onsite_details(conn, %{"id" => id}) do
    # Get the current patient from the session
    patient = conn.assigns.current_patient
    
    case Appointments.get_appointment(id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found.")
        |> redirect(to: ~p"/patient/dashboard")
        
      appointment ->
        # Check if the appointment belongs to the current patient
        if appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_by_appointment(appointment.id)
          
          # Check if this is an onsite appointment and payment is complete
          if appointment.appointment_type == "onsite" && invoice && invoice.status == "paid" do
            # Get clinic details
            clinic = get_clinic_details(appointment.clinic_id)
            
            render(conn, :onsite_details, appointment: appointment, clinic: clinic)
          else
            conn
            |> put_flash(:error, "Onsite details are only available for paid onsite appointments.")
            |> redirect(to: ~p"/q/appointment/#{appointment.id}")
          end
        else
          conn
          |> put_flash(:error, "You don't have permission to view this appointment.")
          |> redirect(to: ~p"/patient/dashboard")
        end
    end
  end
  
  # Helper functions
  
  defp get_or_generate_meeting_link(appointment) do
    # Check if the appointment already has a meeting link
    if appointment.meeting_link && appointment.meeting_link != "" do
      appointment.meeting_link
    else
      # Generate a new meeting link
      # This is a placeholder - in a real implementation, you would integrate with
      # a video conferencing API (Zoom, Google Meet, etc.) to generate a real link
      link = "https://meet.clinicpro.com/#{appointment.id}-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
      
      # Update the appointment with the new link
      {:ok, updated_appointment} = Appointments.update_appointment(appointment, %{meeting_link: link})
      
      link
    end
  end
  
  defp get_clinic_details(clinic_id) do
    # This is a placeholder - in a real implementation, you would fetch the clinic details from the database
    # For now, we'll return a mock clinic object
    %{
      id: clinic_id,
      name: "ClinicPro Medical Center",
      address: "123 Health Street, Medical District",
      phone: "+254 712 345 678",
      email: "appointments@clinicpro.com",
      directions: "Located on the 3rd floor of the Medical Plaza building. Parking available in the basement."
    }
  end
end
