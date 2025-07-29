defmodule Clinicpro.Paystack.Callback do
  @moduledoc """
  Module for handling Paystack webhook callbacks.

  This module processes webhook notifications from Paystack and updates
  transaction statuses accordingly, maintaining proper multi-tenant isolation.
  """

  alias Clinicpro.Paystack.{Transaction, WebhookLog}
  # # alias Clinicpro.Repo
  import Ecto.Query

  require Logger

  @doc """
  Processes a webhook callback from Paystack.

  ## Parameters

  - `payload` - The webhook payload from Paystack
  - `clinic_id` - The ID of the clinic
  - `signature` - The signature from the X-Paystack-Signature header

  ## Returns

  - `{:ok, webhook_log}` - If the callback was processed successfully
  - `{:error, reason}` - If processing failed
  """
  def process_webhook(payload, clinic_id, signature) when is_map(payload) do
    # Start processing time measurement
    start_time = System.monotonic_time(:millisecond)

    # Extract event type and reference
    event_type = Map.get(payload, "event")
    reference = get_in(payload, ["data", "reference"])

    # Create initial webhook log entry
    {:ok, webhook_log} =
      WebhookLog.create(%{
        event_type: event_type,
        reference: reference,
        payload: payload,
        status: :pending,
        clinic_id: clinic_id,
        processing_history: [
          %{
            status: :started,
            message: "Webhook received",
            timestamp: DateTime.utc_now()
          }
        ]
      })

    # Process the webhook
    result =
      with :ok <- verify_signature(Jason.encode!(payload), signature),
           :ok <- process_event(payload, webhook_log) do
        # Calculate processing time
        end_time = System.monotonic_time(:millisecond)
        processing_time = end_time - start_time

        # Mark webhook as processed
        transaction_id = webhook_log.transaction_id

        {:ok, _updated_webhook} =
          WebhookLog.mark_as_processed(webhook_log, transaction_id, processing_time)

        {:ok, _updated_webhook}
      else
        {:error, reason} ->
          # Mark webhook as failed
          error_message = "Failed to process webhook: #{inspect(reason)}"
          Logger.error(error_message)

          {:ok, _updated_webhook} = WebhookLog.mark_as_failed(webhook_log, error_message)
          {:error, reason}
      end

    result
  end

  def process_webhook(payload, clinic_id, signature) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, decoded_payload} -> process_webhook(decoded_payload, clinic_id, signature)
      {:error, reason} -> {:error, {:invalid_json, reason}}
    end
  end

  # Private functions

  defp verify_signature(payload, [signature]) when is_binary(payload) and is_binary(signature) do
    # Get the default secret key for webhook verification
    # In a production environment, you might want to verify against all clinic secret keys
    case Application.get_env(:clinicpro, :paystack_default_secret_key) do
      nil ->
        {:error, :no_default_secret_key}

      secret_key ->
        # Calculate the expected signature
        expected_signature =
          :crypto.mac(:hmac, :sha512, secret_key, payload)
          |> Base.encode16(case: :lower)

        # Compare with the provided signature
        if Plug.Crypto.secure_compare(expected_signature, signature) do
          :ok
        else
          {:error, :invalid_signature}
        end
    end
  end

  defp verify_signature(_payload, _signature) do
    {:error, :invalid_signature_format}
  end

  defp process_event(%{"event" => "charge.success"} = event_data, webhook_log) do
    # Extract data from the event
    data = event_data["data"]
    reference = data["reference"]

    # Update the transaction
    case updatetransaction(reference, webhook_log.clinic_id, data) do
      {:ok, transaction} ->
        # Update webhook log with transaction ID
        WebhookLog.update(webhook_log, %{transaction_id: transaction.id})
        :ok

      error ->
        error
    end
  end

  defp process_event(%{"event" => "transfer.success"} = _event_data, _webhook_log) do
    # Handle transfer success events (e.g., payouts to clinics)
    # Implementation would depend on your specific requirements
    :ok
  end

  defp process_event(%{"event" => event_type}, _webhook_log) do
    # Log other event types but don't process them
    Logger.info("Received unhandled Paystack event: #{event_type}")
    :ok
  end

  defp process_event(_unused1, _unused2) do
    {:error, :invalid_event_data}
  end

  defp updatetransaction(reference, clinic_id, data) do
    # Find the transaction by reference
    case Transaction.get_by_reference(reference, clinic_id) do
      {:ok, transaction} ->
        # Update transaction status
        status = data["status"]
        Transaction.update(transaction, %{status: status})

      {:error, :not_found} ->
        # Create a new transaction record if it doesn't exist
        # This might happen if the webhook arrives before our system creates the transaction
        Transaction.create(%{
          reference: reference,
          amount: data["amount"],
          status: data["status"],
          customer_email: data["customer"]["email"],
          clinic_id: clinic_id
        })
    end
  end

  # Unused function
  # defp create_transaction_from_webhook(reference, clinic_id, data) do
  # Commented out due to undefined variables
  # attrs = %{
  #   clinic_id: clinic_id,
  #   email: data["customer"]["email"],
  #   amount: data["amount"],
  #   reference: reference,
  #   paystack_reference: data["id"],
  #   description: data["description"] || "Payment from webhook",
  #   status: if(data["status"] == "success", do: "completed", else: "failed"),
  #   payment_date: parse_datetime(data["paid_at"]),
  #   channel: data["channel"],
  #   currency: data["currency"],
  #   fees: data["fees"],
  #   gateway_response: data["gateway_response"],
  #   metadata: data["metadata"] || %{}
  # }

  # case Transaction.create(attrs) do
  #   {:ok, _transaction} -> :ok
  #   {:error, changeset} -> {:error, {:transaction_creation_failed, changeset}}
  # end
  # end

  #   defp find_clinic_id_from_reference(reference) do
  #     # Try to extract clinic_id from the reference if it follows a pattern
  #     # This is a fallback and depends on your reference generation strategy
  # Example: "CLINIC_123_INV_456" -> clinic_id = 123
  # case Regex.run(~r/CLINIC_(\d+)_unused/, reference) do
  #   [_unused, clinic_id] -> String.to_integer(clinic_id)
  #   _unused -> nil
  # end
  # end

  #   defp parse_datetime(nil), do: nil
  # 
  #   defp parse_datetime(datetime_string) do
  #     case DateTime.from_iso8601(datetime_string) do
  #       {:ok, datetime, _unused} -> datetime
  #       _unused -> nil
  #     end
  #   end

  @doc """
  Retries processing a failed webhook by its ID and clinic_id.
  Ensures multi-tenant isolation by requiring clinic_id.

  ## Parameters
  - id: The ID of the webhook log to retry
  - clinic_id: The clinic ID for multi-tenant isolation

  ## Returns
  - {:ok, webhook_log} on success
  - {:error, reason} on failure
  """
  def retry_webhook(id, clinic_id) when is_binary(id) and is_integer(clinic_id) do
    # Find the webhook log by ID and clinic_id to ensure multi-tenant isolation
    query =
      from w in WebhookLog,
        where: w.id == ^id and w.clinic_id == ^clinic_id

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      webhook_log ->
        # Only allow retrying failed webhooks
        if webhook_log.status == "failed" do
          # Start processing time measurement
          start_time = System.monotonic_time(:millisecond)

          # Process the webhook based on event type
          result = process_event(webhook_log.payload, webhook_log)

          # Calculate processing time
          end_time = System.monotonic_time(:millisecond)
          processing_time = end_time - start_time

          # Update webhook log based on processing result
          case result do
            :ok ->
              # Mark webhook as processed
              WebhookLog.mark_as_processed(
                webhook_log,
                webhook_log.transaction_id,
                processing_time
              )

            {:error, reason} ->
              # Mark webhook as failed
              error_message = "Failed to process webhook: #{inspect(reason)}"
              WebhookLog.mark_as_failed(webhook_log, error_message)
          end
        else
          {:error, :not_failed}
        end
    end
  end

  def retry_webhook(id, clinic_id) when is_integer(id) do
    retry_webhook(Integer.to_string(id), clinic_id)
  end
end
