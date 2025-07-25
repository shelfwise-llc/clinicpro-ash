defmodule ClinicproWeb.AppointmentController do
  use ClinicproWeb, :controller

  alias Clinicpro.Appointments
  alias Clinicpro.Invoices

  @doc """
  Show _appointment details.
  """
  def show(conn, %{"id" => id}) do
    # Get the current patient from the session
    patient = conn.assigns.current_patient

    case Appointments.get_appointment(id) do
      nil ->
        conn
        |> put_flash(:error, "Appointment not found.")
        |> redirect(to: ~p"/patient/dashboard")

      _appointment ->
        # Check if the _appointment belongs to the current patient
        if _appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_by_appointment(_appointment.id)

          render(conn, :show, _appointment: _appointment, invoice: invoice)
        else
          conn
          |> put_flash(:error, "You don't have permission to view this _appointment.")
          |> redirect(to: ~p"/patient/dashboard")
        end
    end
  end

  @doc """
  Show virtual _appointment link.
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

      _appointment ->
        # Check if the _appointment belongs to the current patient
        if _appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_by_appointment(_appointment.id)

          # Check if this is a virtual _appointment and payment is complete
          if _appointment.appointment_type == "virtual" && invoice && invoice.status == "paid" do
            # Generate or retrieve virtual meeting link
            meeting_link = get_or_generate_meeting_link(_appointment)

            render(conn, :virtual_link, _appointment: _appointment, meeting_link: meeting_link)
          else
            conn
            |> put_flash(:error, "Virtual link is only available for paid virtual appointments.")
            |> redirect(to: ~p"/q/_appointment/#{_appointment.id}")
          end
        else
          conn
          |> put_flash(:error, "You don't have permission to view this _appointment.")
          |> redirect(to: ~p"/patient/dashboard")
        end
    end
  end

  @doc """
  Show onsite _appointment details.
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

      _appointment ->
        # Check if the _appointment belongs to the current patient
        if _appointment.patient_id == patient.id do
          # Get the associated invoice
          invoice = Invoices.get_invoice_by_appointment(_appointment.id)

          # Check if this is an onsite _appointment and payment is complete
          if _appointment.appointment_type == "onsite" && invoice && invoice.status == "paid" do
            # Get clinic details
            clinic = get_clinic_details(_appointment._clinic_id)

            render(conn, :onsite_details, _appointment: _appointment, clinic: clinic)
          else
            conn
            |> put_flash(
              :error,
              "Onsite details are only available for paid onsite appointments."
            )
            |> redirect(to: ~p"/q/_appointment/#{_appointment.id}")
          end
        else
          conn
          |> put_flash(:error, "You don't have permission to view this _appointment.")
          |> redirect(to: ~p"/patient/dashboard")
        end
    end
  end

  # Helper functions

  defp get_or_generate_meeting_link(_appointment) do
    # Check if the _appointment already has a meeting link
    if _appointment.meeting_link && _appointment.meeting_link != "" do
      _appointment.meeting_link
    else
      # Get the _clinic_id from the _appointment context
      # In a multi-tenant system, we need to determine which clinic this _appointment belongs to
      # This could be from the doctor's association, the patient's association, or from the current session

      # For now, we'll get the _clinic_id from the doctor's association
      # In a real implementation, you would have a proper way to get the _clinic_id
      _clinic_id = get_clinic_id_for_appointment(_appointment)

      # Use the VirtualMeetings adapter to create a meeting
      case Clinicpro.VirtualMeetings.Adapter.create_meeting(_appointment, [], _clinic_id) do
        {:ok, meeting_data} ->
          # Extract the meeting link from the response
          link = meeting_data.join_url || meeting_data.meeting_url

          # Update the _appointment with the new link
          {:ok, _updated_appointment} =
            Appointments.update_appointment(_appointment, %{meeting_link: link})

          link

        {:error, reason} ->
          # Log the error
          require Logger
          Logger.error("Failed to create virtual meeting: #{inspect(reason)}")

          # Fall back to a simple meeting link as a last resort
          link =
            "https://meet.clinicpro.com/#{_appointment.id}-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

          # Update the _appointment with the fallback link
          {:ok, _updated_appointment} =
            Appointments.update_appointment(_appointment, %{meeting_link: link})

          link
      end
    end
  end

  defp get_clinic_id_for_appointment(_appointment) do
    # In a real implementation, you would have a proper way to get the _clinic_id
    # This is a placeholder implementation

    # Option 1: Get from doctor's association if doctor belongs to a clinic
    # doctor = Repo.get(Doctor, _appointment.doctor_id)
    # doctor._clinic_id

    # Option 2: Get from the current session or context
    # conn.assigns.current_clinic_id

    # For now, we'll use a placeholder _clinic_id for testing
    # Replace this with the actual logic to get the _clinic_id
    "11111111-1111-1111-1111-111111111111"
  end

  defp get_clinic_details(_clinic_id) do
    # This is a placeholder - in a real implementation, you would fetch the clinic details from the database
    # For now, we'll return a mock clinic object
    %{
      id: _clinic_id,
      name: "ClinicPro Medical Center",
      address: "123 Health Street, Medical District",
      phone: "+254 712 345 678",
      email: "appointments@clinicpro.com",
      directions:
        "Located on the 3rd floor of the Medical Plaza building. Parking available in the basement."
    }
  end
end
