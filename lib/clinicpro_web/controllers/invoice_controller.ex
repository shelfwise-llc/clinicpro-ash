defmodule ClinicproWeb.InvoiceController do
  use ClinicproWeb, :controller
  # # alias Clinicpro.Repo
  alias Clinicpro.AdminBypass.{Invoice, Patient, Doctor, Appointment}
  alias Clinicpro.MPesa
  alias Phoenix.PubSub
  alias Clinicpro.Invoices
  alias Clinicpro.MPesa.InvoiceIntegration

  # List invoices for a clinic
  def index(conn, %{"_clinic_id" => _clinic_id} = params) do
    with {:ok, clinic} <- get_clinic(_clinic_id) do
      _page = Map.get(params, "_page", "1") |> String.to_integer()
      _per_page = 20

      # Extract filter parameters
      status = Map.get(params, "status")
      patient_id = Map.get(params, "patient_id")

      # Apply filters
      filters = %{_clinic_id: _clinic_id}
      filters = if status, do: Map.put(filters, :status, status), else: filters
      filters = if patient_id, do: Map.put(filters, :patient_id, patient_id), else: filters

      invoices = Invoice.list_invoices(filters)

      # Get statistics for the dashboard
      stats = Invoice.get_stats_for_clinic(_clinic_id)

      # Get _patients for filter dropdown
      _patients = Patient.list_patients()

      render(conn, :index,
        _clinic_id: _clinic_id,
        clinic_name: clinic.name,
        invoices: invoices,
        stats: stats,
        _patients: _patients,
        status: status,
        patient_id: patient_id
      )
    end
  end

  # Show invoice details
  def show(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    with {:ok, clinic} <- get_clinic(_clinic_id),
         invoice <- Invoice.get_invoice!(id) do
      # Check if invoice belongs to this clinic
      if invoice._clinic_id != _clinic_id do
        conn
        |> put_flash(:error, "Invoice not found")
        |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
      else
        # Get M-Pesa transactions for this invoice
        transactions = InvoiceIntegration.get_invoice_transactions(id, _clinic_id)

        # Get payment status
        payment_status = InvoiceIntegration.get_invoice_payment_status(id, _clinic_id)

        render(conn, :show,
          _clinic_id: _clinic_id,
          clinic_name: clinic.name,
          invoice: invoice,
          transactions: transactions,
          payment_status: payment_status
        )
      end
    end
  end

  # New invoice form
  def new(conn, %{"_clinic_id" => _clinic_id}) do
    with {:ok, clinic} <- get_clinic(_clinic_id) do
      changeset =
        Invoice.change_invoice(%Invoice{
          _clinic_id: _clinic_id,
          # Default due date: 30 days from today
          due_date: Date.utc_today() |> Date.add(30)
        })

      _patients = Patient.list_patients()
      appointments = Appointment.list_appointments_for_clinic(_clinic_id)

      render(conn, :new,
        _clinic_id: _clinic_id,
        clinic_name: clinic.name,
        changeset: changeset,
        _patients: _patients,
        appointments: appointments
      )
    end
  end

  # Create invoice
  def create(conn, %{"_clinic_id" => _clinic_id, "invoice" => invoice_params}) do
    with {:ok, clinic} <- get_clinic(_clinic_id) do
      # Ensure _clinic_id is set
      invoice_params = Map.put(invoice_params, "_clinic_id", _clinic_id)

      case Invoice.create_invoice(invoice_params) do
        {:ok, invoice} ->
          conn
          |> put_flash(:info, "Invoice created successfully.")
          |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          _patients = Patient.list_patients()
          appointments = Appointment.list_appointments_for_clinic(_clinic_id)

          render(conn, :new,
            _clinic_id: _clinic_id,
            clinic_name: clinic.name,
            changeset: changeset,
            _patients: _patients,
            appointments: appointments
          )
      end
    end
  end

  # Edit invoice form
  def edit(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    with {:ok, clinic} <- get_clinic(_clinic_id),
         invoice <- Invoice.get_invoice!(id) do
      # Check if invoice belongs to this clinic
      if invoice._clinic_id != _clinic_id do
        conn
        |> put_flash(:error, "Invoice not found")
        |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
      else
        changeset = Invoice.change_invoice(invoice)
        _patients = Patient.list_patients()
        appointments = Appointment.list_appointments_for_clinic(_clinic_id)

        render(conn, :edit,
          _clinic_id: _clinic_id,
          clinic_name: clinic.name,
          invoice: invoice,
          changeset: changeset,
          _patients: _patients,
          appointments: appointments
        )
      end
    end
  end

  # Update invoice
  def update(conn, %{"_clinic_id" => _clinic_id, "id" => id, "invoice" => invoice_params}) do
    with {:ok, clinic} <- get_clinic(_clinic_id),
         invoice <- Invoice.get_invoice!(id) do
      # Check if invoice belongs to this clinic
      if invoice._clinic_id != _clinic_id do
        conn
        |> put_flash(:error, "Invoice not found")
        |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
      else
        case Invoice.update_invoice(invoice, invoice_params) do
          {:ok, updated_invoice} ->
            conn
            |> put_flash(:info, "Invoice updated successfully.")
            |> redirect(
              to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{updated_invoice.id}"
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            _patients = Patient.list_patients()
            appointments = Appointment.list_appointments_for_clinic(_clinic_id)

            render(conn, :edit,
              _clinic_id: _clinic_id,
              clinic_name: clinic.name,
              invoice: invoice,
              changeset: changeset,
              _patients: _patients,
              appointments: appointments
            )
        end
      end
    end
  end

  # Delete invoice
  def delete(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    with {:ok, _clinic} <- get_clinic(_clinic_id),
         invoice <- Invoice.get_invoice!(id) do
      # Check if invoice belongs to this clinic
      if invoice._clinic_id != _clinic_id do
        conn
        |> put_flash(:error, "Invoice not found")
        |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
      else
        # Only allow deletion of pending invoices
        if invoice.status == "pending" do
          {:ok, _unused} = Invoice.delete_invoice(invoice)

          conn
          |> put_flash(:info, "Invoice deleted successfully.")
          |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
        else
          conn
          |> put_flash(:error, "Only pending invoices can be deleted.")
          |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}")
        end
      end
    end
  end

  # Process payment form
  def payment_form(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    with {:ok, clinic} <- get_clinic(_clinic_id),
         invoice <- Invoice.get_invoice!(id) do
      # Check if invoice belongs to this clinic
      if invoice._clinic_id != _clinic_id do
        conn
        |> put_flash(:error, "Invoice not found")
        |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
      else
        # Only allow payment for pending or partial invoices
        if invoice.status in ["pending", "partial"] do
          # Pre-fill phone from patient if available
          payment_phone =
            if invoice.patient && invoice.patient.phone, do: invoice.patient.phone, else: ""

          changeset = Invoice.change_invoice(invoice, %{payment_phone: payment_phone})

          render(conn, :payment_form,
            _clinic_id: _clinic_id,
            clinic_name: clinic.name,
            invoice: invoice,
            changeset: changeset
          )
        else
          conn
          |> put_flash(:error, "This invoice cannot be paid.")
          |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}")
        end
      end
    end
  end

  # Process payment
  def process_payment(conn, %{"_clinic_id" => _clinic_id, "id" => id, "payment" => payment_params}) do
    with {:ok, _clinic} <- get_clinic(_clinic_id),
         invoice <- Invoice.get_invoice!(id) do
      # Check if invoice belongs to this clinic
      if invoice._clinic_id != _clinic_id do
        conn
        |> put_flash(:error, "Invoice not found")
        |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
      else
        # Only allow payment for pending or partial invoices
        if invoice.status in ["pending", "partial"] do
          phone = Map.get(payment_params, "phone")
          amount = Map.get(payment_params, "amount") |> Decimal.new()

          case Invoice.process_payment(invoice, phone, amount) do
            {:ok, _transaction} ->
              # Subscribe to _transaction updates
              PubSub.subscribe(Clinicpro.PubSub, "mpesa:_transaction:#{_transaction.reference}")

              conn
              |> put_flash(
                :info,
                "Payment initiated. Please check your phone to complete the payment."
              )
              |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}")

            {:error, reason} ->
              conn
              |> put_flash(:error, "Failed to initiate payment: #{inspect(reason)}")
              |> redirect(
                to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}/payment"
              )
          end
        else
          conn
          |> put_flash(:error, "This invoice cannot be paid.")
          |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}")
        end
      end
    end
  end

  # Patient invoices
  def patient_invoices(conn, %{"patient_id" => patient_id}) do
    patient = Patient.get_patient!(patient_id)
    invoices = Invoice.list_invoices(%{patient_id: patient_id})

    render(conn, :patient_invoices,
      patient: patient,
      invoices: invoices
    )
  end

  # Initiates an STK Push payment for an invoice.
  def initiate_payment(conn, %{
        "_clinic_id" => _clinic_id,
        "id" => id,
        "phone_number" => phone_number
      }) do
    with {:ok, _clinic} <- get_clinic(_clinic_id),
         invoice <- Invoice.get_invoice!(id) do
      # Check if invoice belongs to this clinic
      if invoice._clinic_id != _clinic_id do
        conn
        |> put_flash(:error, "Invoice not found")
        |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices")
      else
        case InvoiceIntegration.initiate_stk_push_for_invoice(id, _clinic_id, phone_number) do
          {:ok, _transaction} ->
            conn
            |> put_flash(
              :info,
              "Payment request sent to #{phone_number}. Please check your phone to complete the payment."
            )
            |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}")

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to initiate payment: #{reason}")
            |> redirect(to: ~p"/admin_bypass/clinics/#{_clinic_id}/invoices/#{invoice.id}")
        end
      end
    end
  end

  # Private functions

  defp get_clinic(_clinic_id) do
    case Repo.get(Doctor, _clinic_id) do
      nil -> {:error, :not_found}
      clinic -> {:ok, clinic}
    end
  end
end
