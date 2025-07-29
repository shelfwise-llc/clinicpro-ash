defmodule ClinicproWeb.DoctorController do
  use ClinicproWeb, :controller

  alias Clinicpro.{Repo, Doctor, Patient, Appointment}
  import Ecto.Query

  @doc """
  Doctor dashboard - shows overview of patients and appointments
  """
  def dashboard(conn, _params) do
    doctor_id = get_session(conn, :doctor_id)

    # Get doctor info
    doctor = Repo.get!(Doctor, doctor_id)

    # Get today's appointments
    today = Date.utc_today()

    today_appointments =
      from(a in Appointment,
        where: a.doctor_id == ^doctor_id and a.date == ^today,
        preload: [:patient]
      )
      |> Repo.all()

    # Get recent patients
    recent_patients =
      from(p in Patient,
        join: a in Appointment,
        on: a.patient_id == p.id,
        where: a.doctor_id == ^doctor_id,
        distinct: p.id,
        order_by: [desc: a.inserted_at],
        limit: 5,
        preload: [:appointments]
      )
      |> Repo.all()

    # Get appointment stats
    total_appointments =
      from(a in Appointment, where: a.doctor_id == ^doctor_id)
      |> Repo.aggregate(:count, :id)

    pending_appointments =
      from(a in Appointment,
        where: a.doctor_id == ^doctor_id and a.status == "Scheduled"
      )
      |> Repo.aggregate(:count, :id)

    conn
    |> assign(:doctor, doctor)
    |> assign(:today_appointments, today_appointments)
    |> assign(:recent_patients, recent_patients)
    |> assign(:total_appointments, total_appointments)
    |> assign(:pending_appointments, pending_appointments)
    |> render("dashboard.html")
  end

  @doc """
  List all patients for this doctor
  """
  def patients(conn, _params) do
    doctor_id = get_session(conn, :doctor_id)

    patients =
      from(p in Patient,
        join: a in Appointment,
        on: a.patient_id == p.id,
        where: a.doctor_id == ^doctor_id,
        distinct: p.id,
        order_by: [asc: p.name],
        preload: [:appointments]
      )
      |> Repo.all()

    conn
    |> assign(:patients, patients)
    |> render("patients.html")
  end

  @doc """
  Show specific patient details
  """
  def show_patient(conn, %{"id" => patient_id}) do
    doctor_id = get_session(conn, :doctor_id)

    # Verify this doctor has appointments with this patient
    patient_appointments =
      from(a in Appointment,
        where: a.doctor_id == ^doctor_id and a.patient_id == ^patient_id
      )
      |> Repo.all()

    if Enum.empty?(patient_appointments) do
      conn
      |> put_flash(:error, "Patient not found or not assigned to you.")
      |> redirect(to: ~p"/doctor/patients")
    else
      patient = Repo.get!(Patient, patient_id)

      appointments =
        from(a in Appointment,
          where: a.doctor_id == ^doctor_id and a.patient_id == ^patient_id,
          order_by: [desc: a.appointment_date]
        )
        |> Repo.all()

      conn
      |> assign(:patient, patient)
      |> assign(:appointments, appointments)
      |> render("show_patient.html")
    end
  end

  @doc """
  List all appointments for this doctor
  """
  def appointments(conn, _params) do
    doctor_id = get_session(conn, :doctor_id)

    appointments =
      from(a in Appointment,
        where: a.doctor_id == ^doctor_id,
        order_by: [desc: a.date],
        preload: [:patient]
      )
      |> Repo.all()

    conn
    |> assign(:appointments, appointments)
    |> render("appointments.html")
  end

  @doc """
  Show specific appointment details
  """
  def show_appointment(conn, %{"id" => appointment_id}) do
    doctor_id = get_session(conn, :doctor_id)

    appointment =
      from(a in Appointment,
        where: a.id == ^appointment_id and a.doctor_id == ^doctor_id,
        preload: [:patient]
      )
      |> Repo.one()

    if appointment do
      conn
      |> assign(:appointment, appointment)
      |> render("show_appointment.html")
    else
      conn
      |> put_flash(:error, "Appointment not found.")
      |> redirect(to: ~p"/doctor/appointments")
    end
  end

  @doc """
  Update appointment status or notes
  """
  def update_appointment(conn, %{"id" => appointment_id, "appointment" => appointment_params}) do
    doctor_id = get_session(conn, :doctor_id)

    appointment =
      from(a in Appointment,
        where: a.id == ^appointment_id and a.doctor_id == ^doctor_id
      )
      |> Repo.one()

    if appointment do
      case Ecto.Changeset.change(appointment, appointment_params) |> Repo.update() do
        {:ok, _appointment} ->
          conn
          |> put_flash(:info, "Appointment updated successfully.")
          |> redirect(to: ~p"/doctor/appointments/#{appointment_id}")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to update appointment.")
          |> redirect(to: ~p"/doctor/appointments/#{appointment_id}")
      end
    else
      conn
      |> put_flash(:error, "Appointment not found.")
      |> redirect(to: ~p"/doctor/appointments")
    end
  end
end
