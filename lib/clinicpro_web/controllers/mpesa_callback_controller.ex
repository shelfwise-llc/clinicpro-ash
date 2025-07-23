defmodule ClinicproWeb.MPesaCallbackController do
  @moduledoc """
  Controller for handling M-Pesa payment callbacks.
  Supports multi-tenant architecture with clinic-specific callback handling.
  """

  use ClinicproWeb, :controller

  alias Clinicpro.MPesa.Callback
  alias Clinicpro.Invoices.PaymentProcessor

  require Logger

  @doc """
  Handle STK Push callbacks from M-Pesa.
  Updates transaction and invoice status based on the payment result.
  """
  def stk_callback(conn, %{"Body" => body} = params) do
    # Log the callback for debugging
    Logger.info("Received M-Pesa STK callback: #{inspect(params)}")

    # Extract the clinic ID from the callback URL path
    # The URL format is expected to be /api/mpesa/callbacks/:clinic_id/stk
    clinic_id = conn.path_params["clinic_id"]

    # Process the callback with the Callback module (handles validation and parsing)
    case Callback.process_stk_callback(body, clinic_id) do
      {:ok, callback_data} ->
        # Update the transaction and invoice status
        case PaymentProcessor.process_callback(callback_data) do
          {:ok, %{invoice: invoice, transaction: transaction}} ->
            # Log the successful processing
            Logger.info("Successfully processed M-Pesa payment for invoice #{invoice.id}, transaction #{transaction.id}")

            # Return success response to M-Pesa
            conn
            |> put_status(:ok)
            |> json(%{
              "ResultCode" => 0,
              "ResultDesc" => "Success"
            })

          {:error, reason} ->
            # Log the error
            Logger.error("Failed to process M-Pesa callback: #{inspect(reason)}")

            # Return error response to M-Pesa
            conn
            |> put_status(:internal_server_error)
            |> json(%{
              "ResultCode" => 1,
              "ResultDesc" => "Failed to process callback"
            })
        end

      {:error, reason} ->
        # Log the error
        Logger.error("Invalid M-Pesa STK callback: #{inspect(reason)}")

        # Return error response to M-Pesa
        conn
        |> put_status(:bad_request)
        |> json(%{
          "ResultCode" => 1,
          "ResultDesc" => "Invalid callback data"
        })
    end
  end

  @doc """
  Handle C2B validation requests from M-Pesa.
  Validates that the transaction is for a valid invoice in the system.
  """
  def c2b_validation(conn, %{"Body" => body} = params) do
    # Log the validation request for debugging
    Logger.info("Received M-Pesa C2B validation request: #{inspect(params)}")

    # Extract the clinic ID from the callback URL path
    clinic_id = conn.path_params["clinic_id"]

    # Process the validation request
    case Callback.process_c2b_validation(body, clinic_id) do
      {:ok, %{reference: reference}} ->
        # Check if the reference number matches a valid invoice
        case Clinicpro.Invoices.get_invoice_by_reference(reference, clinic_id) do
          nil ->
            # No matching invoice found
            conn
            |> put_status(:ok)
            |> json(%{
              "ResultCode" => 1,
              "ResultDesc" => "Rejected: Invalid reference number"
            })

          _invoice ->
            # Invoice found, accept the payment
            conn
            |> put_status(:ok)
            |> json(%{
              "ResultCode" => 0,
              "ResultDesc" => "Accepted"
            })
        end

      {:error, reason} ->
        # Log the error
        Logger.error("Invalid M-Pesa C2B validation request: #{inspect(reason)}")

        # Return error response
        conn
        |> put_status(:bad_request)
        |> json(%{
          "ResultCode" => 1,
          "ResultDesc" => "Invalid validation request"
        })
    end
  end

  @doc """
  Handle C2B confirmation callbacks from M-Pesa.
  Updates the invoice status based on the payment confirmation.
  """
  def c2b_confirmation(conn, %{"Body" => body} = params) do
    # Log the confirmation for debugging
    Logger.info("Received M-Pesa C2B confirmation: #{inspect(params)}")

    # Extract the clinic ID from the callback URL path
    clinic_id = conn.path_params["clinic_id"]

    # Process the confirmation
    case Callback.process_c2b_confirmation(body, clinic_id) do
      {:ok, confirmation_data} ->
        # Extract the reference number and amount
        %{
          reference: reference,
          amount: amount,
          transaction_id: transaction_id,
          phone_number: phone_number
        } = confirmation_data

        # Find the invoice by reference number
        case Clinicpro.Invoices.get_invoice_by_reference(reference, clinic_id) do
          nil ->
            # No matching invoice found, log the orphaned payment
            Logger.warning("Received M-Pesa payment for unknown reference: #{reference}")

            # Create an orphaned transaction record for reconciliation
            Clinicpro.MPesa.Transaction.create_orphaned(%{
              transaction_id: transaction_id,
              amount: amount,
              phone_number: phone_number,
              reference: reference,
              clinic_id: clinic_id,
              status: "orphaned"
            })

            # Return success to M-Pesa (we've recorded the payment)
            conn
            |> put_status(:ok)
            |> json(%{
              "ResultCode" => 0,
              "ResultDesc" => "Success"
            })

          invoice ->
            # Create a transaction record and update the invoice
            {:ok, _transaction} = Clinicpro.MPesa.Transaction.create(%{
              transaction_id: transaction_id,
              invoice_id: invoice.id,
              amount: amount,
              phone_number: phone_number,
              reference: reference,
              clinic_id: clinic_id,
              status: "completed"
            })

            # Update the invoice status
            {:ok, _updated_invoice} = Clinicpro.Invoices.update_invoice(invoice, %{
              status: "paid",
              payment_status: "completed",
              payment_date: DateTime.utc_now(),
              payment_reference: transaction_id
            })

            # If this is an appointment invoice, update the appointment status
            if invoice.appointment_id do
              appointment = Clinicpro.Appointments.get_appointment(invoice.appointment_id)

              if appointment do
                {:ok, _updated_appointment} = Clinicpro.Appointments.update_appointment(appointment, %{
                  payment_status: "paid"
                })
              end
            end

            # Return success to M-Pesa
            conn
            |> put_status(:ok)
            |> json(%{
              "ResultCode" => 0,
              "ResultDesc" => "Success"
            })
        end

      {:error, reason} ->
        # Log the error
        Logger.error("Invalid M-Pesa C2B confirmation: #{inspect(reason)}")

        # Return error response
        conn
        |> put_status(:bad_request)
        |> json(%{
          "ResultCode" => 1,
          "ResultDesc" => "Invalid confirmation data"
        })
    end
  end
end
