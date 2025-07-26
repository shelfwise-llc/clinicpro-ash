defmodule Clinicpro.BookingFlowTest do
  @moduledoc """
  End-to-end test for the core booking flow.

  This test covers the scenario where:
  1. Guest accesses a booking page without authentication
  2. Guest books an appointment with a doctor
  3. Doctor logs into the clinic system
  4. Doctor views their bookings
  5. Doctor accesses patient's medical history
  """
  use Clinicpro.DataCase, async: true

  alias Clinicpro.Accounts
  alias Clinicpro.Clinics
  alias Clinicpro.Patients
  alias Clinicpro.Appointments

  describe "booking flow" do
    test "end-to-end booking flow from guest to doctor viewing history" do
      # Working backwards from the end goal

      # STEP 5: Doctor views patient history
      # Expected outcome: Doctor can see full patient history including past appointments
      doctor_views_patient_history = fn doctor_token, patient_id ->
        # Doctor retrieves patient history with their auth token
        {:ok, patient_with_history} = Patients.get_patient_with_history(patient_id, doctor_token)

        # Assertions to verify doctor can see patient history
        assert patient_with_history.id == patient_id
        assert length(patient_with_history.appointments) > 0
        assert patient_with_history.medical_history != nil

        patient_with_history
      end

      # STEP 4: Doctor views their bookings
      # Expected outcome: Doctor can see the booking made by the guest
      doctor_views_bookings = fn doctor_token, doctor_id ->
        # Doctor retrieves their appointments with their auth token
        {:ok, appointments} = Appointments.list_doctor_appointments(doctor_id, doctor_token)

        # Assertions to verify doctor can see appointments
        assert length(appointments) > 0
        [appointment | _unused] = appointments
        assert appointment.status == :scheduled

        # Return the first appointment for use in next step
        {appointment, appointments}
      end

      # STEP 3: Doctor logs into the clinic system
      # Expected outcome: Doctor receives authentication token
      doctor_logs_in = fn doctor_user ->
        # Doctor requests magic link
        {:ok, _unused} = Accounts.request_magic_link(%{email: doctor_user.email})

        # In a real system, doctor would receive email and click link
        # For test purposes, we'll simulate the token verification
        {:ok, doctor_token} = Accounts.authenticate_by_email(doctor_user.email)

        # Assertions to verify doctor is authenticated
        assert doctor_token.user_id == doctor_user.id

        doctor_token
      end

      # STEP 2: Guest books an appointment
      # Expected outcome: Appointment is created and linked to a patient record
      guest_books_appointment = fn clinic, doctor_staff ->
        # Guest fills out booking form with their information
        booking_params = %{
          patient: %{
            first_name: "Jane",
            last_name: "Doe",
            email: "jane.doe@example.com",
            phone: "5555555555",
            date_of_birth: ~D[1990-01-01],
            gender: :female
          },
          appointment: %{
            clinic_id: clinic.id,
            doctor_id: doctor_staff.id,
            scheduled_at: DateTime.utc_now() |> DateTime.add(2, :day),
            duration_minutes: 30,
            reason: "Annual checkup",
            notes: "First visit"
          }
        }

        # Guest submits booking form
        {:ok, %{patient: patient, appointment: appointment}} =
          Appointments.create_guest_booking(booking_params)

        # Assertions to verify booking was created
        assert patient.email == "jane.doe@example.com"
        assert appointment.clinic_id == clinic.id
        assert appointment.doctor_id == doctor_staff.id
        assert appointment.status == :scheduled

        {patient, appointment}
      end

      # STEP 1: Setup clinic and doctor (prerequisite)
      # Expected outcome: Clinic and doctor exist in the system
      setup_clinic_and_doctor = fn ->
        # Create a clinic
        {:ok, clinic} =
          Clinics.register(%{
            name: "Test Clinic",
            address: "123 Test St",
            phone: "1234567890",
            email: "clinic@example.com",
            website: "https://testclinic.com",
            slug: "test-clinic"
          })

        # Create a doctor user
        {:ok, doctor_user} =
          Accounts.register(%{
            email: "doctor@example.com",
            first_name: "Doctor",
            last_name: "Smith",
            phone_number: "0987654321"
          })

        # Add doctor to clinic
        {:ok, doctor_staff} =
          Clinics.add_staff_member(%{
            clinic_id: clinic.id,
            user_id: doctor_user.id,
            role: :doctor
          })

        {clinic, doctor_user, doctor_staff}
      end

      # Execute the test steps in the correct order
      {clinic, doctor_user, doctor_staff} = setup_clinic_and_doctor.()
      {patient, appointment} = guest_books_appointment.(clinic, doctor_staff)
      doctor_token = doctor_logs_in.(doctor_user)
      {appointment, appointments} = doctor_views_bookings.(doctor_token, doctor_staff.id)
      patient_with_history = doctor_views_patient_history.(doctor_token, patient.id)

      # Final assertions to verify the entire flow
      assert patient_with_history.id == patient.id
      assert Enum.any?(patient_with_history.appointments, fn apt -> apt.id == appointment.id end)
    end
  end
end
