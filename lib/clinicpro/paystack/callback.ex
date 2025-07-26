defmodule Clinicpro.Paystack.Callback do
  @moduledoc """
  Module for handling Paystack webhook callbacks.

  This module processes webhook notifications from Paystack and updates
  _transaction statuses accordingly, maintaining proper multi-tenant isolation.
  """

  alias Clinicpro.Paystack.{Config, Transaction, WebhookLog}
  # # alias Clinicpro.Repo
  import Ecto.Query

  require Logger

  @doc """
  Processes a webhook callback from Paystack.

  ## Parameters

  - `payload` - The webhook payload from Paystack
  - `_clinic_id` - The ID of the clinic
  - `signature` - The signature from the X-Paystack-Signature header

  ## Returns

  - `{:ok, webhook_log}` - If the callback was processed successfully
  - `{:error, reason}` - If processing failed
  """
  def process_webhook(payload, _clinic_id, signature) when is_map(payload) do
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
        _clinic_id: _clinic_id,
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

        {:ok, updated_webhook} =
          WebhookLog.mark_as_processed(webhook_log, transaction_id, processing_time)

        {:ok, updated_webhook}
      else
        {:error, reason} ->
          # Mark webhook as failed
          error_message = "Failed to process webhook: #{inspect(reason)}"
          Logger.error(error_message)

          {:ok, updated_webhook} = WebhookLog.mark_as_failed(webhook_log, error_message)
          {:error, reason}
      end

    result
  end

  def process_webhook(payload, _clinic_id, signature) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, decoded_payload} -> process_webhook(decoded_payload, _clinic_id, signature)
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

    # Update the _transaction
    case update_transaction(reference, webhook_log._clinic_id, data) do
      {:ok, _transaction} ->
        # Update webhook log with _transaction ID
        WebhookLog.update(webhook_log, %{transaction_id: _transaction.id})
        :ok

      error ->
        error
    end
  end

  defp process_event(%{"event" => "transfer.success"} = event_data, webhook_log) do
    # Handle transfer success events (e.g., payouts to clinics)
    # Implementation would depend on your specific requirements
    :ok
  end

  defp process_event(%{"event" => event_type}, webhook_log) do
    # Log other event types but don't process them
    Logger.info("Received unhandled Paystack event: #{event_type}")
    :ok
  end

  defp process_event(_unused, _unused) do
    {:error, :invalid_event_data}
  end

  defp update_transaction(reference, _clinic_id, data) do
    # Find the _transaction by reference
    case Transaction.get_by_reference(reference, _clinic_id) do
      {:ok, _transaction} ->
        # Update _transaction status
        status = data["status"]
        Transaction.update(_transaction, %{status: status})

      {:error, :not_found} ->
        # Create a new _transaction record if it doesn't exist
        # This might happen if the webhook arrives before our system creates the _transaction
        Transaction.create(%{
          reference: reference,
          amount: data["amount"],
          status: data["status"],
          customer_email: data["customer"]["email"],
          _clinic_id: _clinic_id
        })
    end
  end

  defp create_transaction_from_webhook(reference, _clinic_id, data) do
    attrs = %{
      _clinic_id: _clinic_id,
      email: data["customer"]["email"],
      amount: data["amount"],
      reference: reference,
      paystack_reference: data["id"],
      description: data["description"] || "Payment from webhook",
      status: if(data["status"] == "success", do: "completed", else: "failed"),
      payment_date: parse_datetime(data["paid_at"]),
      channel: data["channel"],
      currency: data["currency"],
      fees: data["fees"],
      gateway_response: data["gateway_response"],
      metadata: data["metadata"] || %{}
    }

    case Transaction.create(attrs) do
      {:ok, _transaction} -> :ok
      {:error, changeset} -> {:error, {:transaction_creation_failed, changeset}}
    end
  end

  defp find_clinic_id_from_reference(reference) do
    # Try to extract _clinic_id from the reference if it follows a pattern
    # This is a fallback and depends on your reference generation strategy
    # Example: "CLINIC_123_INV_456" -> _clinic_id = 123
    case Regex.run(~r/CLINIC_(\d+)_unused/, reference) do
      [_unused, _clinic_id] -> String.to_integer(_clinic_id)
      _unused -> nil
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _unused} -> datetime
      _unused -> nil
    end
  end

  @doc """
  Retries processing a failed webhook by its ID and _clinic_id.
  Ensures multi-tenant isolation by requiring _clinic_id.

  ## Parameters
  - id: The ID of the webhook log to retry
  - _clinic_id: The clinic ID for multi-tenant isolation

  ## Returns
  - {:ok, webhook_log} on success
  - {:error, reason} on failure
  """
  def retry_webhook(id, _clinic_id) when is_binary(id) and is_integer(_clinic_id) do
    # Find the webhook log by ID and _clinic_id to ensure multi-tenant isolation
    query =
      from w in WebhookLog,
        where: w.id == ^id and w._clinic_id == ^_clinic_id

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

  def retry_webhook(id, _clinic_id) when is_integer(id) do
    retry_webhook(Integer.to_string(id), _clinic_id)
  end
end
