defmodule Clinicpro.Appointments do
  @moduledoc """
  Appointments context for ClinicPro.

  This context handles appointment scheduling, management, and guest bookings.
  """
  # Temporarily removed AshAuthentication for development
  use Ash.Api

  resources do
    resource Clinicpro.Appointments.Appointment
  end

  authorization do
    authorize :by_default
  end

  # Authentication configuration commented out for development
  # We're using the AuthPlaceholder module instead
  #
  # authentication do
  #   strategies do
  #     magic_link :magic_link do
  #       identity_field(:email)
  #       sender(Clinicpro.Accounts.MagicLinkSender)
  #       sign_in_tokens_enabled?(true)
  #     end
  #   end
  # end

  @doc """
  Lists appointments for a specific doctor.

  ## Examples

      iex> list_doctor_appointments(doctor_id, auth_token)
      {:ok, [%Appointment{...}, ...]}

  """
  def list_doctor_appointments(doctor_id, auth_token \\ nil) do
    require Ash.Query
    Clinicpro.Appointments.Appointment
    |> Ash.Query.filter(Ash.Query.expr(doctor_id == ^doctor_id))
    |> Ash.Query.load([:patient, :clinic])
    |> Ash.read(actor: auth_token && auth_token.user)
  end

  @doc """
  Creates a booking from a guest (no authentication required).

  This function handles the complete flow of:
  1. Creating or finding a patient record
  2. Creating an appointment

  ## Examples

      iex> create_guest_booking(%{patient: %{...}, appointment: %{...}})
      {:ok, %{patient: %Patient{...}, appointment: %Appointment{...}}}

  """
  def create_guest_booking(params) do
    patient_params = params.patient
    appointment_params = params.appointment

    # Transaction to ensure both patient and appointment are created together
    # Using Ecto.Multi for transaction since we're bypassing Ash APIs temporarily
    Ecto.Multi.new()
    |> Ecto.Multi.run(:patient, fn _repo, _changes ->
      # First, try to find existing patient by email
      patient_result =
        require Ash.Query
        case Clinicpro.Patients.Patient
             |> Ash.Query.filter(Ash.Query.expr(email == ^patient_params.email))
             |> Ash.read_one() do
          {:ok, existing_patient} ->
            {:ok, existing_patient}
          {:error, _} ->
            # Create new patient if not found
            # Using direct Ecto operations instead of Ash APIs
            Clinicpro.Patient.create(%{
              first_name: patient_params.first_name,
              last_name: patient_params.last_name,
              email: patient_params.email,
              phone: patient_params.phone,
              date_of_birth: patient_params.date_of_birth,
              gender: patient_params.gender,
              active: true
            })
        end

      patient_result
    end)
    |> Ecto.Multi.run(:appointment, fn _repo, %{patient: patient} ->
      # Create appointment with patient
      Clinicpro.Appointment.create(Map.put(appointment_params, :patient_id, patient.id))
    end)
    |> Clinicpro.Repo.transaction()
    |> case do
      {:ok, %{patient: patient, appointment: appointment}} ->
        {:ok, %{patient: patient, appointment: appointment}}
      {:error, _failed_operation, failed_value, _changes} ->
        {:error, failed_value}
    end
  end

  @doc """
  Creates a new appointment.

  ## Examples

      iex> create_new_appointment(%{doctor_id: "123", patient_id: "456", ...})
      {:ok, %Appointment{...}}

  """
  def create_new_appointment(params) do
    # Using direct Ecto operations instead of Ash APIs
    Clinicpro.Appointment.create(params)
  end
end
