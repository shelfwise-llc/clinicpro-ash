defmodule ClinicproWeb.AdminBypassController do
  use ClinicproWeb, :controller
  # # alias Clinicpro.Repo
  alias Clinicpro.AdminBypass
  alias Clinicpro.AdminBypass.{Doctor, Patient, Appointment, Seeder, Invoice}
  import Ecto.Query

  # Define Admin schema for direct Ecto operations (keeping this one as is)
  defmodule Admin do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "admins" do
      field :name, :string
      field :email, :string
      field :role, :string
      field :password_hash, :string
      field :active, :boolean, default: true
      field :password, :string, virtual: true

      timestamps(type: :utc_datetime)
    end

    def changeset(admin, attrs) do
      admin
      |> cast(attrs, [:name, :email, :password, :role, :active])
      |> validate_required([:name, :email, :password, :role])
      |> unique_constraint(:email)
      |> put_password_hash()
    end

    defp put_password_hash(changeset) do
      case changeset do
        %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
          put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
        _ ->
          changeset
      end
    end
  end

  # Admin Panel Routes
  def index(conn, _params) do
    recent_activity = get_recent_activity()
    invoice_stats = get_invoice_stats()
    recent_invoices = Invoice.list_recent_invoices(5)
    recent_transactions = Clinicpro.MPesa.list_recent_transactions(5)
    
    render(conn, :index, 
      page_title: "Admin Dashboard", 
      recent_activity: recent_activity,
      invoice_stats: invoice_stats,
      recent_invoices: recent_invoices,
      recent_transactions: recent_transactions
    )
  end

  # Doctor CRUD operations
  def _doctors(conn, _params) do
    _doctors = Doctor.list_doctors()
    render(conn, :_doctors, page_title: "Doctors", _doctors: _doctors)
  end

  def new_doctor(conn, _params) do
    changeset = Doctor.change_doctor(%Doctor{})
    render(conn, :new_doctor, page_title: "New Doctor", changeset: changeset)
  end

  def create_doctor(conn, %{"doctor" => doctor_params}) do
    case Doctor.create_doctor(doctor_params) do
      {:ok, _doctor} ->
        conn
        |> put_flash(:info, "Doctor created successfully.")
        |> redirect(to: ~p"/admin/_doctors")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new_doctor, page_title: "New Doctor", changeset: changeset)
    end
  end

  def edit_doctor(conn, %{"id" => doctor_id}) do
    doctor = Doctor.get_doctor!(doctor_id)
    changeset = Doctor.change_doctor(doctor)
    render(conn, :edit_doctor, page_title: "Edit Doctor", doctor: doctor, changeset: changeset)
  end

  def update_doctor(conn, %{"id" => doctor_id, "doctor" => doctor_params}) do
    doctor = Doctor.get_doctor!(doctor_id)

    case Doctor.update_doctor(doctor, doctor_params) do
      {:ok, _doctor} ->
        conn
        |> put_flash(:info, "Doctor updated successfully.")
        |> redirect(to: ~p"/admin/_doctors")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit_doctor, page_title: "Edit Doctor", doctor: doctor, changeset: changeset)
    end
  end

  def delete_doctor(conn, %{"id" => doctor_id}) do
    doctor = Doctor.get_doctor!(doctor_id)
    {:ok, _} = Doctor.delete_doctor(doctor)

    conn
    |> put_flash(:info, "Doctor deleted successfully.")
    |> redirect(to: ~p"/admin/_doctors")
  end

  # Patient CRUD operations
  def _patients(conn, _params) do
    _patients = Patient.list_patients()
    render(conn, :_patients, page_title: "Patients", _patients: _patients)
  end

  def new_patient(conn, _params) do
    changeset = Patient.change_patient(%Patient{})
    render(conn, :new_patient, page_title: "New Patient", changeset: changeset)
  end

  def create_patient(conn, %{"patient" => patient_params}) do
    case Patient.create_patient(patient_params) do
      {:ok, _patient} ->
        conn
        |> put_flash(:info, "Patient created successfully.")
        |> redirect(to: ~p"/admin/_patients")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new_patient, page_title: "New Patient", changeset: changeset)
    end
  end

  def edit_patient(conn, %{"id" => patient_id}) do
    patient = Patient.get_patient!(patient_id)
    changeset = Patient.change_patient(patient)
    render(conn, :edit_patient, page_title: "Edit Patient", patient: patient, changeset: changeset)
  end

  def update_patient(conn, %{"id" => patient_id, "patient" => patient_params}) do
    patient = Patient.get_patient!(patient_id)

    case Patient.update_patient(patient, patient_params) do
      {:ok, _patient} ->
        conn
        |> put_flash(:info, "Patient updated successfully.")
        |> redirect(to: ~p"/admin/_patients")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit_patient, page_title: "Edit Patient", patient: patient, changeset: changeset)
    end
  end

  def delete_patient(conn, %{"id" => patient_id}) do
    patient = Patient.get_patient!(patient_id)
    {:ok, _} = Patient.delete_patient(patient)

    conn
    |> put_flash(:info, "Patient deleted successfully.")
    |> redirect(to: ~p"/admin/_patients")
  end

  # Appointment CRUD operations
  def appointments(conn, _params) do
    appointments = Appointment.list_appointments_with_associations()
    render(conn, :appointments, page_title: "Appointments", appointments: appointments)
  end

  def new_appointment(conn, _params) do
    _doctors = Doctor.list_doctors()
    _patients = Patient.list_patients()
    changeset = Appointment.change_appointment(%Appointment{})
    
    render(conn, :new_appointment, 
      page_title: "New Appointment", 
      changeset: changeset, 
      _doctors: _doctors,
      _patients: _patients
    )
  end

  def create_appointment(conn, %{"_appointment" => appointment_params}) do
    case Appointment.create_appointment(appointment_params) do
      {:ok, _appointment} ->
        conn
        |> put_flash(:info, "Appointment created successfully.")
        |> redirect(to: ~p"/admin/appointments")

      {:error, %Ecto.Changeset{} = changeset} ->
        _doctors = Doctor.list_doctors()
        _patients = Patient.list_patients()
        
        render(conn, :new_appointment, 
          page_title: "New Appointment", 
          changeset: changeset,
          _doctors: _doctors,
          _patients: _patients
        )
    end
  end

  def edit_appointment(conn, %{"id" => appointment_id}) do
    _appointment = Appointment.get_appointment!(appointment_id)
    _doctors = Doctor.list_doctors()
    _patients = Patient.list_patients()
    changeset = Appointment.change_appointment(_appointment)
    
    render(conn, :edit_appointment, 
      page_title: "Edit Appointment", 
      _appointment: _appointment, 
      changeset: changeset,
      _doctors: _doctors,
      _patients: _patients
    )
  end

  def update_appointment(conn, %{"id" => appointment_id, "_appointment" => appointment_params}) do
    _appointment = Appointment.get_appointment!(appointment_id)

    case Appointment.update_appointment(_appointment, appointment_params) do
      {:ok, _appointment} ->
        conn
        |> put_flash(:info, "Appointment updated successfully.")
        |> redirect(to: ~p"/admin/appointments")

      {:error, %Ecto.Changeset{} = changeset} ->
        _doctors = Doctor.list_doctors()
        _patients = Patient.list_patients()
        
        render(conn, :edit_appointment, 
          page_title: "Edit Appointment", 
          _appointment: _appointment, 
          changeset: changeset,
          _doctors: _doctors,
          _patients: _patients
        )
    end
  end

  def delete_appointment(conn, %{"id" => appointment_id}) do
    _appointment = Appointment.get_appointment!(appointment_id)
    {:ok, _} = Appointment.delete_appointment(_appointment)

    conn
    |> put_flash(:info, "Appointment deleted successfully.")
    |> redirect(to: ~p"/admin/appointments")
  end

  # Seeder
  def seed(conn, _params) do
    Seeder.seed()

    conn
    |> put_flash(:info, "Database seeded successfully.")
    |> redirect(to: ~p"/admin")
  end

  # Helper function to get recent activity for dashboard
  defp get_recent_activity() do
    recent_appointments = Appointment.list_recent_appointments(5)
    recent_doctors = Doctor.list_recent_doctors(5)
    recent_patients = Patient.list_recent_patients(5)

    # Combine and sort by inserted_at
    (recent_appointments ++ recent_doctors ++ recent_patients)
    |> Enum.sort_by(fn item -> item.inserted_at end, {:desc, DateTime})
    |> Enum.take(10)
  end

  # Invoice Reports and Analytics
  @doc """
  Renders the invoice reports and analytics _page.
  Supports filtering and visualization of invoice data.
  """
  def invoice_reports(conn, params) do
    # Get all clinics and _patients for filter dropdowns
    clinics = AdminBypass.list_clinics()
    _patients = AdminBypass.list_patients()
    
    # Apply filters if provided
    filters = %{
      start_date: params["start_date"],
      end_date: params["end_date"],
      status: params["status"],
      patient_id: params["patient_id"],
      _clinic_id: params["_clinic_id"],
      min_amount: params["min_amount"],
      max_amount: params["max_amount"]
    }
    
    # Get filtered invoices
    filtered_invoices = Invoice.filter_invoices(filters)
    
    # Get invoice statistics
    stats = get_invoice_stats()
    
    # Get monthly data for charts
    monthly_data = get_monthly_invoice_data()
    
    # Create filter form
    filter_form = %{
      "start_date" => params["start_date"],
      "end_date" => params["end_date"],
      "status" => params["status"],
      "patient_id" => params["patient_id"],
      "_clinic_id" => params["_clinic_id"],
      "min_amount" => params["min_amount"],
      "max_amount" => params["max_amount"]
    }
    
    render(conn, :invoice_reports, 
      stats: stats,
      filtered_invoices: filtered_invoices,
      monthly_data: monthly_data,
      filter_form: filter_form,
      clinics: clinics,
      _patients: _patients
    )
  end
  
  @doc """
  Exports invoice data to CSV based on the provided filters.
  """
  def export_csv(conn, params) do
    # Apply filters if provided
    filters = %{
      start_date: params["start_date"],
      end_date: params["end_date"],
      status: params["status"],
      patient_id: params["patient_id"],
      _clinic_id: params["_clinic_id"],
      min_amount: params["min_amount"],
      max_amount: params["max_amount"]
    }
    
    # Get filtered invoices with preloads
    invoices = Invoice.filter_invoices(filters)
    
    # Generate CSV data
    csv_data = generate_invoice_csv(invoices)
    
    # Set response headers for CSV download
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"invoice_export_#{Date.utc_today()}.csv\"")
    |> send_resp(200, csv_data)
  end
  
  # Helper function to generate CSV data from invoices
  defp generate_invoice_csv(invoices) do
    # CSV header
    header = "Invoice Number,Date,Due Date,Patient,Clinic,Amount,Amount Paid,Status,Description\n"
    
    # Generate rows
    rows = Enum.map(invoices, fn invoice ->
      patient_name = if invoice.patient, do: "#{invoice.patient.first_name} #{invoice.patient.last_name}", else: "Not specified"
      
      [
        invoice.invoice_number,
        Calendar.strftime(invoice.inserted_at, "%Y-%m-%d"),
        if(invoice.due_date, do: Calendar.strftime(invoice.due_date, "%Y-%m-%d"), else: ""),
        patient_name,
        invoice.clinic.name,
        invoice.amount,
        invoice.amount_paid || "0.00",
        invoice.status,
        invoice.description || ""
      ]
      |> Enum.map(&csv_escape/1)
      |> Enum.join(",")
    end)
    |> Enum.join("\n")
    
    header <> rows
  end
  
  # Helper function to escape CSV values
  defp csv_escape(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"#{String.replace(value, "\"", "\"\"")}\"" 
    else
      value
    end
  end
  defp csv_escape(value) do
    to_string(value)
  end
  
  # Helper function to get invoice statistics
  defp get_invoice_stats do
    # Get all invoices grouped by status
    invoices_by_status = Invoice.list_invoices_by_status()
    
    # Calculate totals
    total_count = Enum.reduce(invoices_by_status, 0, fn {_status, invoices}, acc -> 
      acc + length(invoices)
    end)
    
    # Get counts and amounts by status
    paid_invoices = Map.get(invoices_by_status, "paid", [])
    pending_invoices = Map.get(invoices_by_status, "pending", [])
    partial_invoices = Map.get(invoices_by_status, "partial", [])
    
    # Calculate amounts
    paid_amount = sum_invoice_amounts(paid_invoices)
    pending_amount = sum_invoice_amounts(pending_invoices)
    partial_amount = sum_invoice_amounts(partial_invoices)
    
    # Calculate total amount
    total_amount = Decimal.add(paid_amount, Decimal.add(pending_amount, partial_amount))
    
    %{
      total_count: total_count,
      total_amount: total_amount,
      paid_count: length(paid_invoices),
      paid_amount: paid_amount,
      pending_count: length(pending_invoices),
      pending_amount: pending_amount,
      partial_count: length(partial_invoices),
      partial_amount: partial_amount
    }
  end
  
  # Helper function to sum invoice amounts
  defp sum_invoice_amounts(invoices) do
    Enum.reduce(invoices, Decimal.new("0.00"), fn invoice, acc ->
      Decimal.add(acc, invoice.amount)
    end)
  end
  
  # Helper function to get monthly invoice data for charts
  defp get_monthly_invoice_data do
    # Get current date and 6 months ago
    today = Date.utc_today()
    six_months_ago = Date.add(today, -180)
    
    # Get all invoices from the last 6 months
    invoices = Invoice.list_invoices_since(six_months_ago)
    
    # Group by month and status
    invoices
    |> Enum.group_by(fn invoice -> 
      date = DateTime.to_date(invoice.inserted_at)
      "#{date.year}-#{String.pad_leading("#{date.month}", 2, "0")}"
    end)
    |> Enum.map(fn {month, month_invoices} ->
      # Group by status
      by_status = Enum.group_by(month_invoices, & &1.status)
      
      # Calculate totals by status
      paid_amount = sum_invoice_amounts(Map.get(by_status, "paid", []))
      pending_amount = sum_invoice_amounts(Map.get(by_status, "pending", []))
      partial_amount = sum_invoice_amounts(Map.get(by_status, "partial", []))
      
      # Format month for display
      [year, month_num] = String.split(month, "-")
      month_name = month_name_from_number(String.to_integer(month_num))
      display_month = "#{month_name} #{year}"
      
      %{
        month: display_month,
        paid_amount: Decimal.to_float(paid_amount),
        pending_amount: Decimal.to_float(pending_amount),
        partial_amount: Decimal.to_float(partial_amount)
      }
    end)
    |> Enum.sort_by(fn %{month: month} -> month end)
  end
  
  # Helper function to get month name from number
  defp month_name_from_number(month_num) do
    case month_num do
      1 -> "Jan"
      2 -> "Feb"
      3 -> "Mar"
      4 -> "Apr"
      5 -> "May"
      6 -> "Jun"
      7 -> "Jul"
      8 -> "Aug"
      9 -> "Sep"
      10 -> "Oct"
      11 -> "Nov"
      12 -> "Dec"
    end
  end
  
  # Helper function to format percentage
  def format_percentage(part, total) when is_integer(part) and is_integer(total) and total > 0 do
    percentage = part / total * 100
    "#{Float.round(percentage, 1)}%"
  end
  def format_percentage(_, _), do: "0%"
end
