defmodule Clinicpro.VirtualMeetingsTest do
  @moduledoc """
  Tests for the virtual meeting integration.
  """

  use Clinicpro.DataCase

  alias Clinicpro.VirtualMeetings.{Adapter, Config, SimpleAdapter}
  alias Clinicpro.AdminBypass.{Appointment, Invoice, Patient, Doctor, Clinic}
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Invoices
  alias Clinicpro.Repo

  describe "virtual meeting adapter configuration" do
    test "get_adapter returns the configured adapter" do
      # Set adapter to SimpleAdapter
      Config.set_adapter(SimpleAdapter)
      assert Adapter.get_adapter() == SimpleAdapter

      # Reset to default for other tests
      Application.delete_env(:clinicpro, :virtual_meeting_adapter)
    end

    test "set_adapter validates that module implements adapter behaviour" do
      # Valid adapter
      assert :ok = Config.set_adapter(SimpleAdapter)

      # Invalid adapter (Kernel doesn't implement the adapter behaviour)
      assert {:error, :invalid_adapter} = Config.set_adapter(Kernel)

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
      # Set up test data
      {:ok, clinic} = Repo.insert(%Clinic{name: "Test Clinic", email: "clinic@example.com"})
      {:ok, doctor} = Repo.insert(%Doctor{first_name: "John", last_name: "Doe", clinic_id: clinic.id})
      {:ok, patient} = Repo.insert(%Patient{first_name: "Jane", last_name: "Smith", email: "patient@example.com"})

      appointment_date = Date.utc_today()
      appointment_time = ~T[10:00:00]

      {:ok, appointment} = Repo.insert(%Appointment{
        patient_id: patient.id,
        clinic_id: clinic.id,
        doctor_id: doctor.id,
        appointment_date: appointment_date,
        appointment_time: appointment_time,
        appointment_type: "virtual",
        status: "pending",
        duration: 30
      })

      {:ok, invoice} = Repo.insert(%Invoice{
        patient_id: patient.id,
        clinic_id: clinic.id,
        appointment_id: appointment.id,
        amount: 1000.0,
        status: "pending",
        reference: "INV-#{:rand.uniform(1000000)}"
      })

      # Ensure SimpleAdapter is configured
      Config.set_adapter(SimpleAdapter)
      Config.set_base_url("https://test.clinicpro.com")

      # Return test data
      %{
        clinic: clinic,
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
      {:ok, updated_appointment} = Appointment.update_appointment(appointment, %{
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
      {:ok, updated_appointment} = Appointment.update_appointment(appointment, %{
        meeting_link: meeting_data.url,
        meeting_data: meeting_data
      })

      # Now delete the meeting
      assert :ok = SimpleAdapter.delete_meeting(updated_appointment)
    end
  end

  describe "payment flow integration" do
    setup do
      # Set up test data
      {:ok, clinic} = Repo.insert(%Clinic{name: "Test Clinic", email: "clinic@example.com"})
      {:ok, doctor} = Repo.insert(%Doctor{first_name: "John", last_name: "Doe", clinic_id: clinic.id})
      {:ok, patient} = Repo.insert(%Patient{first_name: "Jane", last_name: "Smith", email: "patient@example.com"})

      appointment_date = Date.utc_today()
      appointment_time = ~T[10:00:00]

      {:ok, appointment} = Repo.insert(%Appointment{
        patient_id: patient.id,
        clinic_id: clinic.id,
        doctor_id: doctor.id,
        appointment_date: appointment_date,
        appointment_time: appointment_time,
        appointment_type: "virtual",
        status: "pending",
        duration: 30
      })

      reference = "INV-#{:rand.uniform(1000000)}"

      {:ok, invoice} = Repo.insert(%Invoice{
        patient_id: patient.id,
        clinic_id: clinic.id,
        appointment_id: appointment.id,
        amount: 1000.0,
        status: "pending",
        reference: reference
      })

      # Create a mock transaction
      transaction = %Transaction{
        id: "txn_#{:rand.uniform(1000000)}",
        clinic_id: clinic.id,
        reference: reference,
        phone: "254712345678",
        amount: 1000.0,
        status: "completed",
        transaction_date: DateTime.utc_now(),
        mpesa_receipt_number: "LHG31AA3TX"
      }

      # Ensure SimpleAdapter is configured
      Config.set_adapter(SimpleAdapter)
      Config.set_base_url("https://test.clinicpro.com")

      # Return test data
      %{
        clinic: clinic,
        doctor: doctor,
        patient: patient,
        appointment: appointment,
        invoice: invoice,
        transaction: transaction
      }
    end

    test "process_completed_payment creates meeting for virtual appointment", %{transaction: transaction} do
      # Process the payment
      {:ok, updated_invoice} = Invoices.process_completed_payment(transaction)

      # Get the updated appointment
      updated_appointment = Appointment.get_appointment!(updated_invoice.appointment_id)

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
      {:ok, onsite_appointment} = Appointment.update_appointment(appointment, %{appointment_type: "onsite"})

      # Process the payment
      {:ok, updated_invoice} = Invoices.process_completed_payment(transaction)

      # Get the updated appointment
      updated_appointment = Appointment.get_appointment!(updated_invoice.appointment_id)

      # Verify that the appointment is confirmed but doesn't have a meeting link
      assert updated_appointment.status == "confirmed"
      assert updated_appointment.meeting_link == nil
    end
  end
end
