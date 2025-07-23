defmodule Clinicpro.Integration.VirtualMeetingsTest do
  use ClinicproWeb.ConnCase, async: true

  alias Clinicpro.Repo
  alias Clinicpro.Appointment
  alias Clinicpro.Doctor
  alias Clinicpro.Patient
  alias Clinicpro.Clinic
  alias Clinicpro.VirtualMeetings.Adapter
  alias Clinicpro.VirtualMeetings.Config

  @valid_clinic_attrs %{
    name: "Test Clinic",
    address: "123 Test St",
    phone: "+254712345678",
    email: "test@clinic.com"
  }

  @valid_doctor_attrs %{
    name: "Dr. Test",
    specialty: "General",
    email: "doctor@test.com",
    phone: "+254712345679",
    status: "Active",
    active: true
  }

  @valid_patient_attrs %{
    name: "Test Patient",
    email: "patient@test.com",
    phone: "+254712345680"
  }

  @valid_appointment_attrs %{
    date: ~D[2025-08-01],
    start_time: ~T[09:00:00],
    end_time: ~T[10:00:00],
    status: "Scheduled",
    type: "Consultation",
    notes: "Test appointment",
    appointment_type: "virtual"
  }

  setup do
    # Create a test clinic with virtual meeting configuration
    {:ok, clinic} = %Clinic{}
                    |> Clinic.changeset(@valid_clinic_attrs)
                    |> Repo.insert()

    # Set up virtual meeting config for the clinic
    Config.update_clinic_config(clinic.id, %{
      adapter: "google_meet",
      api_credentials: %{
        "type" => "service_account",
        "project_id" => "test-project",
        "client_email" => "test@example.com"
      }
    })

    # Create a test doctor
    {:ok, doctor} = %Doctor{}
                    |> Doctor.changeset(Map.put(@valid_doctor_attrs, :clinic_id, clinic.id))
                    |> Repo.insert()

    # Create a test patient
    {:ok, patient} = %Patient{}
                     |> Patient.changeset(@valid_patient_attrs)
                     |> Repo.insert()

    # Create a test appointment
    appointment_attrs = @valid_appointment_attrs
                        |> Map.put(:doctor_id, doctor.id)
                        |> Map.put(:patient_id, patient.id)
                        |> Map.put(:clinic_id, clinic.id)

    {:ok, appointment} = %Appointment{}
                         |> Appointment.changeset(appointment_attrs)
                         |> Repo.insert()

    %{
      clinic: clinic,
      doctor: doctor,
      patient: patient,
      appointment: appointment
    }
  end

  describe "virtual meetings integration" do
    test "get_or_generate_meeting_link creates a meeting link for a virtual appointment", %{appointment: appointment} do
      # Import the controller to access private functions
      import ClinicproWeb.AppointmentController, only: [get_or_generate_meeting_link: 1]

      # Call the function
      link = get_or_generate_meeting_link(appointment)

      # Assert that a link was generated
      assert link != nil
      assert String.length(link) > 0

      # Verify that the appointment was updated with the link
      updated_appointment = Repo.get(Appointment, appointment.id)
      assert updated_appointment.meeting_link == link
    end

    test "virtual_link action renders the meeting link for a paid virtual appointment", %{
      conn: conn,
      appointment: appointment,
      patient: patient
    } do
      # Create a paid invoice for the appointment
      {:ok, invoice} = Clinicpro.Invoices.create_invoice(%{
        appointment_id: appointment.id,
        amount: 1000.0,
        status: "paid",
        payment_method: "M-Pesa"
      })

      # Log in as the patient
      conn = assign(conn, :current_patient, patient)

      # Call the virtual_link action
      conn = get(conn, ~p"/q/appointment/#{appointment.id}/virtual")

      # Assert that the response contains the meeting link
      assert html_response(conn, 200) =~ "Join Virtual Meeting"
      assert html_response(conn, 200) =~ "meeting_link"
    end

    test "virtual_link action redirects for unpaid virtual appointments", %{
      conn: conn,
      appointment: appointment,
      patient: patient
    } do
      # Create an unpaid invoice for the appointment
      {:ok, invoice} = Clinicpro.Invoices.create_invoice(%{
        appointment_id: appointment.id,
        amount: 1000.0,
        status: "pending",
        payment_method: "M-Pesa"
      })

      # Log in as the patient
      conn = assign(conn, :current_patient, patient)

      # Call the virtual_link action
      conn = get(conn, ~p"/q/appointment/#{appointment.id}/virtual")

      # Assert that we're redirected with an error message
      assert redirected_to(conn) == ~p"/q/appointment/#{appointment.id}"
      assert get_flash(conn, :error) == "Virtual link is only available for paid virtual appointments."
    end
  end
end
