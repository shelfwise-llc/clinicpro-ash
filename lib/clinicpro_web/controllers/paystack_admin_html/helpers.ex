defmodule ClinicproWeb.PaystackAdminHTML.Helpers do
  @moduledoc """
  Helper functions for Paystack admin HTML templates.
  """

  @doc """
  Formats an amount in kobo/cents to a readable currency format.

  ## Examples

      iex> format_amount(100000)
      "1,000.00"

      iex> format_amount(1500)
      "15.00"

  """
  def format_amount(nil), do: "0.00"
  def format_amount(amount) when is_integer(amount) do
    # Convert from kobo/cents to naira/dollars
    amount_in_currency = amount / 100.0

    # Format with commas and 2 decimal places
    :erlang.float_to_binary(amount_in_currency, [decimals: 2])
    |> add_commas()
  end

  @doc """
  Formats a datetime to a readable string.

  ## Examples

      iex> format_datetime(~U[2023-01-01 12:00:00Z])
      "Jan 1, 2023 12:00:00"

  """
  def format_datetime(nil), do: "N/A"
  def format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %d, %Y %H:%M:%S")
  end

  @doc """
  Returns the appropriate CSS class for a _transaction status.

  ## Examples

      iex> status_class("completed")
      "bg-green-100 text-green-800"

      iex> status_class("pending")
      "bg-yellow-100 text-yellow-800"

      iex> status_class("failed")
      "bg-red-100 text-red-800"

  """
  def status_class(status) do
    case status do
      "completed" -> "bg-green-100 text-green-800"
      "pending" -> "bg-yellow-100 text-yellow-800"
      "failed" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  # Private functions

  # Add commas to a number string
  defp add_commas(number_string) do
    [integer_part, decimal_part] = String.split(number_string, ".")

    integer_part
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
    |> Enum.join(",")
    |> Kernel.<>("." <> decimal_part)
  end
end
