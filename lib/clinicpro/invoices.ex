defmodule Clinicpro.Invoices do
  @moduledoc """
  The Invoices context.

  This module provides functions for managing invoices and their relationship
  with M-Pesa payments. It serves as a bridge between the payment system and
  the invoice management system.
  """

  alias Clinicpro.AdminBypass.{Invoice, Appointment}
  # Removed M-Pesa references - using Paystack instead
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
    |> Repo.preload([:patient, :clinic, :appointment])
  end

  @doc """
  Gets an invoice by payment reference.
  """
  def get_invoice_by_reference(reference) do
    Invoice.find_invoice_by_reference(reference)
  end

  @doc """
  Gets an invoice associated with an appointment.
  """
  def get_invoice_byappointment(appointment_id) do
    Invoice
    |> Repo.get_by(appointment_id: appointment_id)
    |> Repo.preload([:patient, :clinic, :appointment])
  end

  @doc """
  Updates an invoice status.
  """
  def update_invoice_status(invoice, status)
      when status in ["pending", "paid", "cancelled", "partial"] do
    Invoice.update_invoice(invoice, %{status: status})
  end

  @doc """
  Processes a completed Paystack transaction and updates the associated invoice.

  This function is called when a payment is completed via Paystack. It:
  1. Updates the invoice status to "paid"
  2. Records the payment details in the invoice notes
  3. Broadcasts an event to notify other parts of the system

  - transaction: The Paystack transaction record

  ## Returns

  - {:ok, invoice} on success
  - {:error, reason} on failure
  """
  def process_completed_payment(transaction) do
    # Verify that the transaction is completed
    if transaction.status == "success" or transaction.status == "completed" do
      # Find the associated invoice
      case Invoice.find_invoice_by_reference(transaction.reference) do
        {:error, :not_found} ->
          Logger.error("No invoice found for transaction reference: #{transaction.reference}")
          {:error, :invoice_not_found}

        {:ok, invoice} ->
          # Update the invoice status to paid
          notes = """
          Payment processed via Paystack:
          Reference: #{transaction.reference}
          Paystack Reference: #{transaction.paystack_reference || "N/A"}
          Date: #{format_transaction_date(transaction.payment_date)}
          Amount: #{transaction.amount}
          Channel: #{transaction.channel || "N/A"}
          """

          case Invoice.update_invoice(invoice, %{
                 status: "paid",
                 notes: append_notes(invoice.notes, notes)
               }) do
            {:ok, updated_invoice} ->
              # Broadcast the payment completion
              broadcast_payment_completed(updated_invoice, transaction)

              # Process the appointment if applicable
              case process_appointment_after_payment(updated_invoice) do
                {:ok, _appointment} ->
                  Logger.info(
                    "Successfully processed appointment for invoice #{updated_invoice.id}"
                  )

                  {:ok, updated_invoice}

                {:error, reason} ->
                  Logger.error(
                    "Failed to process appointment for invoice #{updated_invoice.id}: #{inspect(reason)}"
                  )

                  # We still return success for the payment processing even if appointment processing fails
                  {:ok, updated_invoice}
              end

            {:error, reason} ->
              Logger.error("Failed to update invoice #{invoice.id}: #{inspect(reason)}")
              {:error, reason}
          end
      end
    else
      Logger.info(
        "Ignoring non-completed transaction: #{transaction.id} with status: #{transaction.status}"
      )

      {:error, :not_completed}
    end
  end

  @doc """
  Processes an appointment after payment has been confirmed.
  Handles different appointment types (virtual vs onsite) appropriately.
  """
  def process_appointment_after_payment(invoice) do
    with %{appointment_id: appointment_id} when not is_nil(appointment_id) <- invoice,
         appointment when not is_nil(appointment) <-
           Appointment.get_appointment_with_associations!(appointment_id) do
      # Determine appointment type and handle accordingly
      case appointment.appointment_type do
        "virtual" -> handle_virtualappointment(appointment)
        # Default to onsite handling
        _unused -> handle_onsiteappointment(appointment)
      end
    else
      _unused -> {:error, :appointment_not_found}
    end
  end

  # Private functions

  # M-Pesa related function removed - using Paystack instead

  defp handle_virtualappointment(appointment) do
    # Generate meeting link if not already present
    if is_nil(appointment.meeting_link) || appointment.meeting_link == "" do
      # Use the virtual meeting adapter service to create a meeting
      case create_virtual_meeting(appointment) do
        {:ok, meeting_data} ->
          # Update appointment with meeting link and data
          case Appointment.updateappointment(appointment, %{
                 status: "confirmed",
                 meeting_link: meeting_data.url,
                 meeting_data: meeting_data
               }) do
            {:ok, updatedappointment} ->
              Logger.info(
                "Virtual appointment #{appointment.id} confirmed with meeting link via #{meeting_data.provider}"
              )

              {:ok, updatedappointment}

            {:error, reason} ->
              Logger.error(
                "Failed to update virtual appointment #{appointment.id}: #{inspect(reason)}"
              )

              {:error, reason}
          end

        {:error, reason} ->
          Logger.error(
            "Failed to create virtual meeting for appointment #{appointment.id}: #{inspect(reason)}"
          )

          # Fall back to simple link generation if meeting creation fails
          fallback_link = generate_fallback_meeting_link(appointment.id)

          case Appointment.updateappointment(appointment, %{
                 status: "confirmed",
                 meeting_link: fallback_link
               }) do
            {:ok, updatedappointment} ->
              Logger.info(
                "Virtual appointment #{appointment.id} confirmed with fallback meeting link"
              )

              {:ok, updatedappointment}

            {:error, update_reason} ->
              Logger.error(
                "Failed to update virtual appointment #{appointment.id} with fallback link: #{inspect(update_reason)}"
              )

              {:error, update_reason}
          end
      end
    else
      # Meeting link already exists, just confirm the appointment
      case Appointment.updateappointment(appointment, %{status: "confirmed"}) do
        {:ok, updatedappointment} ->
          Logger.info("Virtual appointment #{appointment.id} confirmed (link already exists)")
          {:ok, updatedappointment}

        {:error, reason} ->
          Logger.error(
            "Failed to confirm virtual appointment #{appointment.id}: #{inspect(reason)}"
          )

          {:error, reason}
      end
    end
  end

  defp handle_onsiteappointment(appointment) do
    # For onsite appointments, just confirm the status
    case Appointment.updateappointment(appointment, %{status: "confirmed"}) do
      {:ok, updatedappointment} ->
        Logger.info("Onsite appointment #{appointment.id} confirmed after payment")
        {:ok, updatedappointment}

      {:error, reason} ->
        Logger.error("Failed to confirm onsite appointment #{appointment.id}: #{inspect(reason)}")

        {:error, reason}
    end
  end

  # Create a virtual meeting using the configured adapter
  defp create_virtual_meeting(appointment) do
    # Get the configured adapter module
    adapter = Clinicpro.VirtualMeetings.Config.get_adapter()

    # Create the meeting using the adapter
    adapter.create_meeting(appointment)
  end

  # Generate a fallback meeting link if the adapter fails
  defp generate_fallback_meeting_link(appointment_id) do
    # This is a fallback method used when the virtual meeting adapter fails
    base_url = System.get_env("VIRTUAL_MEETING_BASE_URL") || "https://meet.clinicpro.com"
    unique_id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)

    "#{base_url}/#{appointment_id}-#{unique_id}"
  end

  defp broadcast_payment_completed(invoice, transaction) do
    # Broadcast to clinic-specific channel
    PubSub.broadcast(
      Clinicpro.PubSub,
      "invoices:#{invoice.clinic_id}",
      {:invoice_paid, invoice, transaction}
    )

    # Broadcast to patient-specific channel
    PubSub.broadcast(
      Clinicpro.PubSub,
      "patient:#{invoice.patient_id}:invoices",
      {:invoice_paid, invoice, transaction}
    )

    # Broadcast to appointment-specific channel if applicable
    if invoice.appointment_id do
      PubSub.broadcast(
        Clinicpro.PubSub,
        "appointment:#{invoice.appointment_id}",
        {:invoice_paid, invoice, transaction}
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
