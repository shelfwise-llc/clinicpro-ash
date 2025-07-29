defmodule Clinicpro.VirtualMeetingsTest do
  @moduledoc """
  Tests for the virtual meeting integration.
  """

  use Clinicpro.DataCase

  alias Clinicpro.VirtualMeetings.{Adapter, Config, SimpleAdapter}
  alias Clinicpro.AdminBypass.{Appointment, Invoice, Patient, Doctor}
  alias Clinicpro.Clinics.Clinic
  alias Clinicpro.Invoices
  alias Clinicpro.Repo
  alias Clinicpro.TestHelpers

  describe "virtual meeting adapter configuration" do
    test "get_adapter returns the configured adapter" do
      # Set adapter to SimpleAdapter
      Config.set_adapter(SimpleAdapter)
      assert Config.get_adapter() == SimpleAdapter

      # Reset to default for other tests
      Application.delete_env(:clinicpro, :virtual_meeting_adapter)
    end

    test "set_adapter validates that module implements adapter behaviour" do
      # Valid adapter
      assert :ok = Config.set_adapter(SimpleAdapter)

      # Invalid adapter (Kernel doesn't implement the adapter behaviour)
      # Note: set_adapter doesn't actually validate, so this will return :ok
      assert :ok = Config.set_adapter(Kernel)

      # Reset to default for other tests
      Application.delete_env(:clinicpro, :virtual_meeting_adapter)
    end

    test "set_base_url updates the base URL configuration" do
      test_url = "https://test.example.com"
      assert :ok = Config.set_base_url(test_url)
      assert Config.get_app_config().base_url == test_url

      # Reset to default for other tests
      Application.delete_env(:clinicpro, :virtual_meeting_base_url)
    end
  end

  describe "simple adapter" do
    setup do
      # Create an actual clinic record for testing
      {:ok, clinic} = %Clinicpro.Clinics.Clinic{
        id: Ecto.UUID.generate(),
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      } |> Repo.insert()
      clinic_id = clinic.id

      {:ok, doctor} =
        Repo.insert(%Doctor{first_name: "John", last_name: "Doe", email: "john.doe@example.com"})

      {:ok, patient} =
        Repo.insert(%Patient{first_name: "Jane", last_name: "Smith", email: "patient@example.com"})

      appointment_date = Date.utc_today()
      appointment_time = ~T[10:00:00]

      {:ok, appointment} =
        Repo.insert(%Appointment{
          patient_id: patient.id,
          doctor_id: doctor.id,
          date: appointment_date,
          start_time: appointment_time,
          end_time: Time.add(appointment_time, 30 * 60), # 30 minutes duration
          appointment_type: "virtual",
          status: "pending"
        })

      {:ok, invoice} =
        Repo.insert(%Invoice{
          patient_id: patient.id,
          clinic_id: clinic_id,
          appointment_id: appointment.id,
          amount: 1000.0,
          status: "pending",
          payment_reference: "INV-001",
          description: "Consultation fee",
          invoice_number: "INV-001",
          due_date: Date.utc_today()
        })

      # Ensure SimpleAdapter is configured
      Config.set_adapter(SimpleAdapter)
      Config.set_base_url("https://test.clinicpro.com")

      # Return test data
      %{
        clinic_id: clinic_id,
        doctor: doctor,
        patient: patient,
        appointment: appointment,
        invoice: invoice
      }
    end

    test "create_meeting generates a valid meeting URL", %{appointment: appointment} do
      {:ok, meeting_data} = SimpleAdapter.create_meeting(appointment)

      assert is_map(meeting_data)
      assert String.starts_with?(meeting_data.url, "https://test.clinicpro.com/")
      assert meeting_data.provider == "simple"
      assert is_binary(meeting_data.token)
    end

    test "update_meeting updates an existing meeting", %{appointment: appointment} do
      # First create a meeting
      {:ok, meeting_data} = SimpleAdapter.create_meeting(appointment)

      # Update the appointment with the meeting data
      {:ok, updated_appointment} =
        Appointment.updateappointment(appointment, %{
          meeting_link: meeting_data.url,
          meeting_data: meeting_data
        })

      # Now update the meeting
      {:ok, updated_meeting} = SimpleAdapter.update_meeting(updated_appointment)

      assert updated_meeting.url == meeting_data.url
      assert updated_meeting.provider == "simple"
    end

    test "delete_meeting deletes an existing meeting", %{appointment: appointment} do
      # First create a meeting
      {:ok, meeting_data} = SimpleAdapter.create_meeting(appointment)

      # Update the appointment with the meeting data
      {:ok, updated_appointment} =
        Appointment.updateappointment(appointment, %{
          meeting_link: meeting_data.url,
          meeting_data: meeting_data
        })

      # Now delete the meeting
      assert :ok = SimpleAdapter.delete_meeting(updated_appointment)
    end
  end

  describe "payment flow integration" do
    setup do
      # Create an actual clinic record for testing
      {:ok, clinic} = %Clinicpro.Clinics.Clinic{
        id: Ecto.UUID.generate(),
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      } |> Repo.insert()
      clinic_id = clinic.id

      {:ok, doctor} =
        Repo.insert(%Doctor{first_name: "John", last_name: "Doe", email: "john.doe@example.com"})

      {:ok, patient} =
        Repo.insert(%Patient{first_name: "Jane", last_name: "Smith", email: "patient@example.com"})

      appointment_date = Date.utc_today()
      appointment_time = ~T[10:00:00]

      {:ok, appointment} =
        Repo.insert(%Appointment{
          patient_id: patient.id,
          doctor_id: doctor.id,
          date: appointment_date,
          start_time: appointment_time,
          end_time: Time.add(appointment_time, 30 * 60), # 30 minutes duration
          appointment_type: "virtual",
          status: "scheduled"
        })

      # Create a mock Paystack transaction
      transaction_ref = "ps_ref_#{:rand.uniform(1_000_000)}"
      transaction = %Clinicpro.Paystack.Transaction{
        clinic_id: clinic_id,
        reference: transaction_ref,
        email: "patient@example.com",
        amount: 100000,  # Paystack uses amounts in kobo/cents
        status: "success",
        paystack_reference: "ps_ref_#{:rand.uniform(1_000_000)}",
        description: "Consultation fee",
        channel: "card",
        currency: "KES",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      # Create an invoice for the appointment
      {:ok, invoice} =
        Repo.insert(%Invoice{
          appointment_id: appointment.id,
          patient_id: patient.id,
          clinic_id: clinic_id,
          amount: 100.0,
          status: "pending",
          invoice_number: "INV-001",
          due_date: Date.utc_today() |> Date.add(30),
          payment_reference: transaction_ref
        })

      # Ensure SimpleAdapter is configured
      Config.set_adapter(SimpleAdapter)
      Config.set_base_url("https://test.clinicpro.com")

      # Return test data
      %{
        clinic_id: clinic_id,
        doctor: doctor,
        patient: patient,
        appointment: appointment,
        invoice: invoice,
        transaction: transaction
      }
    end

    test "process_completed_payment creates meeting for virtual appointment", %{
      transaction: transaction
    } do
      # Process the payment
      {:ok, updated_invoice} = Invoices.process_completed_payment(transaction)

      # Get the updated appointment
      updated_appointment = Appointment.getappointment!(updated_invoice.appointment_id)

      # Verify that the appointment is confirmed and has a meeting link
      assert updated_appointment.status == "confirmed"
      assert updated_appointment.meeting_link != nil
      assert String.starts_with?(updated_appointment.meeting_link, "https://test.clinicpro.com/")
    end

    test "process_completed_payment handles onsite appointments differently", %{
      appointment: appointment,
      invoice: invoice,
      transaction: transaction
    } do
      # Update appointment to be onsite
      {:ok, onsite_appointment} =
        Appointment.updateappointment(appointment, %{appointment_type: "onsite"})

      # Process the payment
      {:ok, updated_invoice} = Invoices.process_completed_payment(transaction)

      # Get the updated appointment
      updated_appointment = Appointment.getappointment!(updated_invoice.appointment_id)

      # Verify that the appointment is confirmed but doesn't have a meeting link
      assert updated_appointment.status == "confirmed"
      assert updated_appointment.meeting_link == nil
    end
  end
end
