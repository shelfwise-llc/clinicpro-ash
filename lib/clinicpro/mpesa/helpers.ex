defmodule Clinicpro.MPesa.Helpers do
  @moduledoc """
  Provides utility functions for the M-Pesa integration.
  This module contains helper functions used across the M-Pesa modules.
  """

  require Logger

  @doc """
  Validates a phone number and formats it to the required M-Pesa format.

  ## Parameters

  - `phone_number` - The phone number to validate and format

  ## Returns

  - `{:ok, formatted_phone}` - If the phone number is valid
  - `{:error, :invalid_phone_number}` - If the phone number is invalid
  """
  def validate_phone_number(phone_number) do
    # Remove any non-digit characters
    digits = String.replace(phone_number, ~r/\D/, "")

    # Format based on different patterns
    formatted =
      cond do
        # If it starts with 254, keep it as is
        String.starts_with?(digits, "254") ->
          digits

        # If it starts with 0, replace with 254
        String.starts_with?(digits, "0") ->
          "254" <> String.slice(digits, 1..-1)

        # If it's 9 digits, assume it's missing the 254 prefix
        String.length(digits) == 9 ->
          "254" <> digits

        # Otherwise, return as is
        true ->
          digits
      end

    # Validate the formatted number
    if String.length(formatted) >= 12 && String.starts_with?(formatted, "254") do
      {:ok, formatted}
    else
      Logger.error("Invalid phone number format: #{phone_number}")
      {:error, :invalid_phone_number}
    end
  end

  @doc """
  Extracts metadata from an STK Push callback.

  ## Parameters

  - `callback_data` - The callback data from M-Pesa

  ## Returns

  - `{:ok, metadata}` - If metadata was successfully extracted
  - `{:error, reason}` - If metadata extraction failed
  """
  def extract_stk_push_metadata(callback_data) do
    try do
      # Extract the metadata from the callback data
      metadata =
        callback_data
        |> get_in(["Body", "stkCallback", "CallbackMetadata", "Item"])
        |> Enum.reduce(%{}, fn item, acc ->
          name = item["Name"]
          value = item["Value"]

          # Map the metadata fields to our internal representation
          case name do
            "Amount" -> Map.put(acc, :amount, value)
            "MpesaReceiptNumber" -> Map.put(acc, :transaction_id, value)
            "TransactionDate" -> Map.put(acc, :transaction_date, format_transaction_date(value))
            "PhoneNumber" -> Map.put(acc, :phone_number, value)
            _unused -> acc
          end
        end)

      {:ok, metadata}
    rescue
      e ->
        Logger.error("Failed to extract STK Push metadata: #{inspect(e)}")
        {:error, :invalid_callback_data}
    end
  end

  @doc """
  Formats a _transaction date from M-Pesa format to ISO format.

  ## Parameters

  - `date_string` - The date string in M-Pesa format (YYYYMMDDHHmmss)

  ## Returns

  - The formatted date string in ISO format
  """
  def format_transaction_date(date_string) when is_binary(date_string) do
    case String.length(date_string) do
      14 ->
        # Format: YYYYMMDDHHmmss
        <<year::binary-size(4), month::binary-size(2), day::binary-size(2), hour::binary-size(2),
          minute::binary-size(2), second::binary-size(2)>> = date_string

        "#{year}-#{month}-#{day}T#{hour}:#{minute}:#{second}Z"

      _unused ->
        # If the format is unexpected, return as is
        date_string
    end
  end

  def format_transaction_date(date_value) when is_integer(date_value) do
    # Convert integer to string and format
    date_value
    |> Integer.to_string()
    |> format_transaction_date()
  end

  def format_transaction_date(date_value), do: date_value

  @doc """
  Generates a unique reference for M-Pesa transactions.

  ## Parameters

  - `prefix` - Optional prefix for the reference

  ## Returns

  - A unique reference string
  """
  def generate_reference(prefix \\ "CP") do
    timestamp = :os.system_time(:millisecond)
    random = :rand.uniform(999)
    "#{prefix}#{timestamp}#{random}"
  end

  @doc """
  Maps a shortcode to a clinic ID.

  ## Parameters

  - `shortcode` - The M-Pesa shortcode

  ## Returns

  - `{:ok, _clinic_id}` - If the mapping was successful
  - `{:error, :shortcode_not_found}` - If the shortcode was not found
  """
  def map_shortcode_to_clinic_id(shortcode) do
    # This would typically query the database to find the clinic with this shortcode
    # For now, we'll use a simple implementation that delegates to the Config module
    alias Clinicpro.MPesa.Config

    case Config.get_clinic_id_from_shortcode(shortcode) do
      nil ->
        Logger.error("No clinic found for shortcode: #{shortcode}")
        {:error, :shortcode_not_found}

      config ->
        {:ok, config._clinic_id}
    end
  end

  @doc """
  Maps an invoice ID to a patient ID.

  ## Parameters

  - `invoice_id` - The invoice ID
  - `_clinic_id` - The clinic ID

  ## Returns

  - `{:ok, patient_id}` - If the mapping was successful
  - `{:error, :invoice_not_found}` - If the invoice was not found
  """
  def map_invoice_to_patient_id(invoice_id, clinic_id) do
    # This would typically query the database to find the patient associated with this invoice
    # For now, we'll use a simple implementation that assumes the Invoice module exists
    alias Clinicpro.Invoice

    case Invoice.get_by_id(invoice_id, clinic_id) do
      nil ->
        Logger.error("No invoice found with ID #{invoice_id} for clinic #{clinic_id}")
        {:error, :invoice_not_found}

      invoice ->
        {:ok, invoice.patient_id}
    end
  end

  @doc """
  Parses a reference string to extract the invoice ID.

  ## Parameters

  - `reference` - The reference string

  ## Returns

  - `{:ok, invoice_id}` - If the parsing was successful
  - `{:error, :invalid_reference}` - If the reference was invalid
  """
  def parse_reference_for_invoice_id(reference) do
    # This would parse the reference string to extract the invoice ID
    # The format depends on how references are generated in your system
    # For now, we'll assume the reference is the invoice ID
    {:ok, reference}
  end
end
