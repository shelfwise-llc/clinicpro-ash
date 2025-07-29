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

    case Appointments.getappointment(id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found.")
        |> redirect(to: ~p"/patient/dashboard")

      appointment ->
        # Check if the appointment belongs to the current patient
        if appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_byappointment(appointment.id)

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

    case Appointments.getappointment(id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found.")
        |> redirect(to: ~p"/patient/dashboard")

      appointment ->
        # Check if the appointment belongs to the current patient
        if appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_byappointment(appointment.id)

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

    case Appointments.getappointment(id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found.")
        |> redirect(to: ~p"/patient/dashboard")

      appointment ->
        # Check if the appointment belongs to the current patient
        if appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_byappointment(appointment.id)

          # Check if this is an onsite appointment and payment is complete
          if appointment.appointment_type == "onsite" && invoice && invoice.status == "paid" do
            # Get clinic details
            clinic = get_clinic_details(appointment.clinic_id)

            render(conn, :onsite_details, appointment: appointment, clinic: clinic)
          else
            conn
            |> put_flash(
              :error,
              "Onsite details are only available for paid onsite appointments."
            )
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
      # Get the clinic_id from the appointment context
      # In a multi-tenant system, we need to determine which clinic this appointment belongs to
      # This could be from the doctor's association, the patient's association, or from the current session

      # For now, we'll get the clinic_id from the doctor's association
      # In a real implementation, you would have a proper way to get the clinic_id
      clinic_id = get_clinic_id_forappointment(appointment)

      # Use the VirtualMeetings adapter to create a meeting
      case Clinicpro.VirtualMeetings.Adapter.create_meeting(appointment, [], clinic_id) do
        {:ok, meeting_data} ->
          # Extract the meeting link from the response
          link = meeting_data.join_url || meeting_data.meeting_url

          # Update the appointment with the new link
          {:ok, _updatedappointment} =
            Appointments.updateappointment(appointment, %{meeting_link: link})

          link

        {:error, reason} ->
          # Log the error
          require Logger
          Logger.error("Failed to create virtual meeting: #{inspect(reason)}")

          # Fall back to a simple meeting link as a last resort
          link =
            "https://meet.clinicpro.com/#{appointment.id}-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

          # Update the appointment with the fallback link
          {:ok, _updatedappointment} =
            Appointments.updateappointment(appointment, %{meeting_link: link})

          link
      end
    end
  end

  defp get_clinic_id_forappointment(appointment) do
    # In a real implementation, you would have a proper way to get the clinic_id
    # This is a placeholder implementation

    # Option 1: Get from doctor's association if doctor belongs to a clinic
    # doctor = Repo.get(Doctor, appointment.doctor_id)
    # doctor.clinic_id

    # Option 2: Get from the current session or context
    # conn.assigns.currentclinic_id

    # For now, we'll use a placeholder clinic_id for testing
    # Replace this with the actual logic to get the clinic_id
    "11111111-1111-1111-1111-111111111111"
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
      directions:
        "Located on the 3rd floor of the Medical Plaza building. Parking available in the basement."
    }
  end
end
