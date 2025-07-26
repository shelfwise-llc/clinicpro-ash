defmodule Clinicpro.Invoices do
  @moduledoc """
  The Invoices context.

  This module provides functions for managing invoices and their relationship
  with M-Pesa payments. It serves as a bridge between the payment system and
  the invoice management system.
  """

  alias Clinicpro.AdminBypass.{Invoice, Appointment}
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Repo
  alias Phoenix.PubSub
  alias Clinicpro.VirtualMeetings.Adapter

  require Logger

  @doc """
  Gets an invoice by ID.
  """
  def get_invoice(id) do
    Invoice
    |> Repo.get(id)
    |> Repo.preload([:patient, :clinic, :_appointment])
  end

  @doc """
  Gets an invoice by payment reference.
  """
  def get_invoice_by_reference(reference) do
    Invoice.find_invoice_by_reference(reference)
  end

  @doc """
  Gets an invoice associated with an _appointment.
  """
  def get_invoice_by_appointment(appointment_id) do
    Invoice
    |> Repo.get_by(appointment_id: appointment_id)
    |> Repo.preload([:patient, :clinic, :_appointment])
  end

  @doc """
  Updates an invoice status.
  """
  def update_invoice_status(invoice, status)
      when status in ["pending", "paid", "cancelled", "partial"] do
    Invoice.update_invoice(invoice, %{status: status})
  end

  @doc """
  Processes a completed M-Pesa _transaction and updates the associated invoice.

  This function is called when a payment is completed via M-Pesa. It:
  1. Updates the invoice status to "paid"
  2. Records the payment details in the invoice notes
  3. Broadcasts an event to notify other parts of the system
  4. Triggers _appointment-specific actions based on the _appointment type

  Returns:
  - {:ok, invoice} on success
  - {:error, reason} on failure
  """
  def process_completed_payment(_transaction = %Transaction{status: "completed"}) do
    with {:ok, invoice} <- Invoice.find_invoice_by_reference(_transaction.reference),
         {:ok, updated_invoice} <- update_invoice_with_payment(invoice, _transaction) do
      # Process _appointment if one exists
      if updated_invoice.appointment_id do
        process_appointment_after_payment(updated_invoice)
      end

      # Broadcast payment completed event
      broadcast_payment_completed(updated_invoice, _transaction)

      Logger.info("Invoice #{updated_invoice.id} marked as paid after successful M-Pesa payment")

      {:ok, updated_invoice}
    else
      {:error, :not_found} ->
        Logger.warning("No invoice found for reference: #{_transaction.reference}")
        {:error, :invoice_not_found}

      {:error, reason} ->
        Logger.error(
          "Failed to update invoice for _transaction #{_transaction.id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  def process_completed_payment(_transaction) do
    Logger.info(
      "Ignoring non-completed _transaction: #{_transaction.id} with status: #{_transaction.status}"
    )

    {:error, :not_completed}
  end

  @doc """
  Processes an _appointment after payment has been confirmed.
  Handles different _appointment types (virtual vs onsite) appropriately.
  """
  def process_appointment_after_payment(invoice) do
    with %{appointment_id: appointment_id} when not is_nil(appointment_id) <- invoice,
         _appointment when not is_nil(_appointment) <-
           Appointment.get_appointment_with_associations!(appointment_id) do
      # Determine _appointment type and handle accordingly
      case _appointment.appointment_type do
        "virtual" -> handle_virtual_appointment(_appointment)
        # Default to onsite handling
        _unused -> handle_onsite_appointment(_appointment)
      end
    else
      _unused -> {:error, :appointment_not_found}
    end
  end

  # Private functions

  defp update_invoice_with_payment(invoice, _transaction) do
    notes = """
    Payment processed via M-Pesa:
    Receipt: #{_transaction.mpesa_receipt_number || "N/A"}
    Date: #{format_transaction_date(_transaction.transaction_date)}
    Amount: #{_transaction.amount || invoice.amount}
    Phone: #{_transaction.phone}
    """

    Invoice.update_invoice(invoice, %{
      status: "paid",
      notes: append_notes(invoice.notes, notes)
    })
  end

  defp handle_virtual_appointment(_appointment) do
    # Generate meeting link if not already present
    if is_nil(_appointment.meeting_link) || _appointment.meeting_link == "" do
      # Use the virtual meeting adapter service to create a meeting
      case create_virtual_meeting(_appointment) do
        {:ok, meeting_data} ->
          # Update _appointment with meeting link and data
          case Appointment.update_appointment(_appointment, %{
                 status: "confirmed",
                 meeting_link: meeting_data.url,
                 meeting_data: meeting_data
               }) do
            {:ok, _updated_appointment} ->
              Logger.info(
                "Virtual _appointment #{_appointment.id} confirmed with meeting link via #{meeting_data.provider}"
              )

              {:ok, _updated_appointment}

            {:error, reason} ->
              Logger.error(
                "Failed to update virtual _appointment #{_appointment.id}: #{inspect(reason)}"
              )

              {:error, reason}
          end

        {:error, reason} ->
          Logger.error(
            "Failed to create virtual meeting for _appointment #{_appointment.id}: #{inspect(reason)}"
          )

          # Fall back to simple link generation if meeting creation fails
          fallback_link = generate_fallback_meeting_link(_appointment.id)

          case Appointment.update_appointment(_appointment, %{
                 status: "confirmed",
                 meeting_link: fallback_link
               }) do
            {:ok, _updated_appointment} ->
              Logger.info(
                "Virtual _appointment #{_appointment.id} confirmed with fallback meeting link"
              )

              {:ok, _updated_appointment}

            {:error, update_reason} ->
              Logger.error(
                "Failed to update virtual _appointment #{_appointment.id} with fallback link: #{inspect(update_reason)}"
              )

              {:error, update_reason}
          end
      end
    else
      # Meeting link already exists, just confirm the _appointment
      case Appointment.update_appointment(_appointment, %{status: "confirmed"}) do
        {:ok, _updated_appointment} ->
          Logger.info("Virtual _appointment #{_appointment.id} confirmed (link already exists)")
          {:ok, _updated_appointment}

        {:error, reason} ->
          Logger.error(
            "Failed to confirm virtual _appointment #{_appointment.id}: #{inspect(reason)}"
          )

          {:error, reason}
      end
    end
  end

  defp handle_onsite_appointment(_appointment) do
    # For onsite appointments, just confirm the status
    case Appointment.update_appointment(_appointment, %{status: "confirmed"}) do
      {:ok, _updated_appointment} ->
        Logger.info("Onsite _appointment #{_appointment.id} confirmed after payment")
        {:ok, _updated_appointment}

      {:error, reason} ->
        Logger.error(
          "Failed to confirm onsite _appointment #{_appointment.id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  # Create a virtual meeting using the configured adapter
  defp create_virtual_meeting(_appointment) do
    # Get the configured adapter module
    adapter = Adapter.get_adapter()

    # Create the meeting using the adapter
    adapter.create_meeting(_appointment)
  end

  # Generate a fallback meeting link if the adapter fails
  defp generate_fallback_meeting_link(appointment_id) do
    # This is a fallback method used when the virtual meeting adapter fails
    base_url = System.get_env("VIRTUAL_MEETING_BASE_URL") || "https://meet.clinicpro.com"
    unique_id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)

    "#{base_url}/#{appointment_id}-#{unique_id}"
  end

  defp broadcast_payment_completed(invoice, _transaction) do
    # Broadcast to clinic-specific channel
    PubSub.broadcast(
      Clinicpro.PubSub,
      "invoices:#{invoice._clinic_id}",
      {:invoice_paid, invoice, _transaction}
    )

    # Broadcast to patient-specific channel
    PubSub.broadcast(
      Clinicpro.PubSub,
      "patient:#{invoice.patient_id}:invoices",
      {:invoice_paid, invoice, _transaction}
    )

    # Broadcast to _appointment-specific channel if applicable
    if invoice.appointment_id do
      PubSub.broadcast(
        Clinicpro.PubSub,
        "_appointment:#{invoice.appointment_id}",
        {:invoice_paid, invoice, _transaction}
      )
    end
  end

  defp append_notes(existing_notes, new_notes) do
    if existing_notes && existing_notes != "" do
      existing_notes <> "\n\n" <> new_notes
    else
      new_notes
    end
  end

  defp format_transaction_date(nil), do: "Unknown"

  defp format_transaction_date(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end
end
