defmodule Clinicpro.MPesa.Callback do
  @moduledoc """
  Processes callbacks from M-Pesa.

  This module is responsible for:
  1. Processing STK Push callbacks
  2. Processing C2B callbacks
  3. Validating callback payloads
  4. Updating transaction records
  5. Broadcasting payment events
  """

  require Logger
  alias Clinicpro.MPesa.Transaction
  alias Phoenix.PubSub

  @doc """
  Processes an STK Push callback from M-Pesa.

  ## Parameters

  - payload: The callback payload from M-Pesa

  ## Returns

  - {:ok, transaction} on success
  - {:error, reason} on failure
  """
  def process_stk(payload) do
    # Extract the Body from the callback payload
    with %{"Body" => body} <- payload,
         # Extract the stkCallback from the body
         %{"stkCallback" => stk_callback} <- body,
         # Extract the CheckoutRequestID
         %{"CheckoutRequestID" => checkout_request_id} <- stk_callback do

      # Find the transaction
      case Transaction.find_by_checkout_request_id(checkout_request_id) do
        {:ok, transaction} ->
          # Update transaction with callback data
          result_code = get_in(stk_callback, ["ResultCode"])
          result_desc = get_in(stk_callback, ["ResultDesc"])

          # Extract receipt number and other details if successful
          metadata = if result_code == "0" do
            item = get_in(stk_callback, ["CallbackMetadata", "Item"]) || []

            %{
              mpesa_receipt_number: find_item_value(item, "MpesaReceiptNumber"),
              transaction_date: parse_transaction_date(find_item_value(item, "TransactionDate")),
              phone: find_item_value(item, "PhoneNumber"),
              amount: find_item_value(item, "Amount")
            }
          else
            %{}
          end

          # Update transaction status
          status = if result_code == "0", do: "completed", else: "failed"

          {:ok, updated_transaction} = Transaction.update(transaction, Map.merge(%{
            status: status,
            result_code: result_code,
            result_desc: result_desc,
            raw_response: payload
          }, metadata))

          # Broadcast the event
          broadcast_transaction_update(updated_transaction)

          {:ok, updated_transaction}

        {:error, :not_found} ->
          # Log unknown transaction
          Logger.warn("Unknown M-Pesa transaction: #{checkout_request_id}")
          {:error, :transaction_not_found}
      end
    else
      error ->
        Logger.error("Invalid M-Pesa STK callback format: #{inspect(error)}")
        {:error, :invalid_callback_format}
    end
  end

  @doc """
  Processes a C2B validation callback from M-Pesa.

  ## Parameters

  - payload: The callback payload from M-Pesa

  ## Returns

  - {:ok, response} - The response to send back to M-Pesa
  """
  def process_c2b_validation(payload) do
    # For validation, we typically just accept all transactions
    # You can add custom validation logic here if needed

    Logger.info("C2B validation received: #{inspect(payload)}")

    # Return a success response
    {:ok, %{
      "ResultCode" => 0,
      "ResultDesc" => "Accepted"
    }}
  end

  @doc """
  Processes a C2B confirmation callback from M-Pesa.

  ## Parameters

  - payload: The callback payload from M-Pesa

  ## Returns

  - {:ok, transaction} on success
  - {:error, reason} on failure
  """
  def process_c2b(payload) do
    # Extract transaction details from the payload
    with %{
           "TransID" => trans_id,
           "TransAmount" => amount,
           "BillRefNumber" => reference,
           "MSISDN" => phone,
           "TransactionType" => transaction_type,
           "BusinessShortCode" => shortcode
         } <- payload do

      # Try to find an existing transaction by reference
      case Transaction.find_by_reference(reference) do
        nil ->
          # This is a new C2B payment, not linked to an existing transaction
          # We need to find which clinic this payment belongs to
          case find_clinic_by_shortcode(shortcode) do
            {:ok, clinic_id} ->
              # Create a new transaction record
              {:ok, transaction} = Transaction.create_pending(%{
                clinic_id: clinic_id,
                reference: reference,
                phone: phone,
                amount: amount,
                type: "c2b",
                description: "C2B Payment: #{transaction_type}"
              })

              # Update with the payment details
              {:ok, updated_transaction} = Transaction.update(transaction, %{
                status: "completed",
                mpesa_receipt_number: trans_id,
                transaction_date: DateTime.utc_now(),
                raw_response: payload
              })

              # Broadcast the event
              broadcast_transaction_update(updated_transaction)

              {:ok, updated_transaction}

            {:error, reason} ->
              Logger.error("Could not determine clinic for C2B payment: #{inspect(reason)}")
              {:error, :clinic_not_found}
          end

        transaction ->
          # This is a C2B payment for an existing transaction
          # Update the transaction with payment details
          {:ok, updated_transaction} = Transaction.update(transaction, %{
            status: "completed",
            mpesa_receipt_number: trans_id,
            transaction_date: DateTime.utc_now(),
            raw_response: payload
          })

          # Broadcast the event
          broadcast_transaction_update(updated_transaction)

          {:ok, updated_transaction}
      end
    else
      error ->
        Logger.error("Invalid M-Pesa C2B callback format: #{inspect(error)}")
        {:error, :invalid_callback_format}
    end
  end

  # Private functions

  defp find_item_value(items, name) do
    Enum.find_value(items, fn item ->
      if item["Name"] == name, do: item["Value"], else: nil
    end)
  end

  defp parse_transaction_date(nil), do: nil
  defp parse_transaction_date(timestamp) do
    # Parse the timestamp from M-Pesa format (YYYYMMDDHHmmss) to DateTime
    case Regex.run(~r/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/, "#{timestamp}") do
      [_, year, month, day, hour, minute, second] ->
        {:ok, datetime} = NaiveDateTime.new(
          String.to_integer(year),
          String.to_integer(month),
          String.to_integer(day),
          String.to_integer(hour),
          String.to_integer(minute),
          String.to_integer(second)
        )
        DateTime.from_naive!(datetime, "Africa/Nairobi")

      _ ->
        nil
    end
  end

  defp broadcast_transaction_update(transaction) do
    # Broadcast to clinic-specific channel
    PubSub.broadcast(
      Clinicpro.PubSub,
      "mpesa:transactions:#{transaction.clinic_id}",
      {:mpesa_transaction_updated, transaction}
    )

    # Broadcast to reference-specific channel
    PubSub.broadcast(
      Clinicpro.PubSub,
      "mpesa:transaction:#{transaction.reference}",
      {:mpesa_transaction_updated, transaction}
    )

    # Broadcast to global channel
    PubSub.broadcast(
      Clinicpro.PubSub,
      "mpesa:transactions",
      {:mpesa_transaction_updated, transaction}
    )
  end

  defp find_clinic_by_shortcode(shortcode) do
    # This function would look up which clinic the shortcode belongs to
    # For now, we'll implement a simple lookup using the mpesa_configs table

    import Ecto.Query
    alias Clinicpro.MPesa.Config

    query = from c in Config,
      where: c.shortcode == ^shortcode or c.c2b_shortcode == ^shortcode,
      select: c.clinic_id,
      limit: 1

    case Clinicpro.Repo.one(query) do
      nil -> {:error, :shortcode_not_found}
      clinic_id -> {:ok, clinic_id}
    end
  end
end
