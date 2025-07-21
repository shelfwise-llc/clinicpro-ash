defmodule ClinicproWeb.MPesaAdminView do
  # Temporarily use a minimal view definition to avoid circular dependencies
  use Phoenix.View,
    root: "lib/clinicpro_web/templates",
    namespace: ClinicproWeb

  @doc """
  Returns a formatted string for the transaction status.
  """
  def format_status("pending"), do: "Pending"
  def format_status("completed"), do: "Completed"
  def format_status("failed"), do: "Failed"
  def format_status(status), do: String.capitalize(status)

  @doc """
  Returns a CSS class for the transaction status.
  """
  def status_class("pending"), do: "bg-warning text-dark"
  def status_class("completed"), do: "bg-success text-white"
  def status_class("failed"), do: "bg-danger text-white"
  def status_class(_), do: "bg-secondary text-white"

  @doc """
  Formats a decimal amount with currency.
  """
  def format_amount(amount) when is_nil(amount), do: "-"

  def format_amount(amount) do
    "KES #{Decimal.round(amount, 2)}"
  end

  @doc """
  Formats a datetime in a readable format.
  """
  def format_datetime(nil), do: "-"

  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%d %b %Y, %H:%M:%S")
  end

  @doc """
  Formats a phone number for display.
  """
  def format_phone(nil), do: "-"

  def format_phone("254" <> rest = _phone) do
    "+254 #{String.slice(rest, 0, 3)} #{String.slice(rest, 3, 3)} #{String.slice(rest, 6, 10)}"
  end

  def format_phone(phone), do: phone

  @doc """
  Returns pagination links for transactions.
  """
  # Temporarily commented out to fix compilation issues
  # def pagination_links(conn, page, total_count, per_page) do
  #   total_pages = ceil(total_count / per_page)
  # 
  #   # Preserve any existing query parameters
  #   query_params = Map.drop(conn.params, ["clinic_id", "page"])
  # 
  #   for p <- max(1, page - 2)..min(total_pages, page + 2) do
  #     Phoenix.HTML.Tag.content_tag :li, class: if(p == page, do: "page-item active", else: "page-item") do
  #       Phoenix.HTML.Link.link to:
  #              Routes.mpesa_admin_path(
  #                conn,
  #                :transactions,
  #                conn.params["clinic_id"],
  #                Map.put(query_params, :page, p)
  #              ),
  #            class: "page-link" do
  #         "#{p}"
  #       end
  #     end
  #   end
  # end
  
  # Simple placeholder function to avoid compilation errors
  def pagination_links(_conn, _page, _total_count, _per_page) do
    []
  end

  @doc """
  Masks sensitive information for display.
  """
  def mask_sensitive(nil), do: nil

  def mask_sensitive(value) when is_binary(value) do
    if String.length(value) > 4 do
      first_chars = String.slice(value, 0, 2)
      last_chars = String.slice(value, -2, 2)
      middle_length = String.length(value) - 4

      first_chars <> String.duplicate("*", middle_length) <> last_chars
    else
      "****"
    end
  end

  @doc """
  Formats transaction statistics for display.
  """
  def format_stats(nil),
    do: %{
      total_count: 0,
      completed_count: 0,
      pending_count: 0,
      failed_count: 0,
      total_amount: Decimal.new(0)
    }

  def format_stats(stats) do
    stats
    |> Map.put(:total_amount_formatted, format_amount(stats.total_amount))
    |> Map.put(
      :completed_percentage,
      calculate_percentage(stats.completed_count, stats.total_count)
    )
    |> Map.put(:pending_percentage, calculate_percentage(stats.pending_count, stats.total_count))
    |> Map.put(:failed_percentage, calculate_percentage(stats.failed_count, stats.total_count))
  end

  @doc """
  Calculates percentage for statistics.
  """
  def calculate_percentage(_count, 0), do: 0

  def calculate_percentage(count, total) do
    Float.round(count / total * 100, 1)
  end

  @doc """
  Returns a CSS class for the environment badge.
  """
  def environment_class("sandbox"), do: "bg-info text-white"
  def environment_class("production"), do: "bg-danger text-white"
  def environment_class(_), do: "bg-secondary text-white"

  @doc """
  Returns a formatted string for the transaction type.
  """
  def format_type("stk_push"), do: "STK PUSH"
  def format_type("c2b"), do: "C2B"

  def format_type(type) when is_binary(type),
    do: String.replace(type, "_", " ") |> String.upcase()

  def format_type(_), do: "UNKNOWN"

  @doc """
  Returns a shortened version of a string for display.
  """
  def truncate(nil, _), do: "-"

  def truncate(string, length) when is_binary(string) do
    if String.length(string) > length do
      "#{String.slice(string, 0, length)}..."
    else
      string
    end
  end

  def truncate(_, _), do: "-"
end
