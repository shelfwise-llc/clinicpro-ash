defmodule ClinicproWeb.MPesaAdminView do
  use ClinicproWeb, :view

  # Explicitly import required modules
  import Phoenix.HTML
  import Phoenix.HTML.Form
  import PhoenixHTMLHelpers.Tag
  import PhoenixHTMLHelpers.Link

  @doc """
  Returns the appropriate CSS class for configuration status display.
  """
  def config_status_class(active) do
    if active, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800"
  end

  @doc """
  Returns the appropriate text for configuration status display.
  """
  def config_status_text(active) do
    if active, do: "Active", else: "Inactive"
  end

  @doc """
  Returns the appropriate CSS class for transaction status display.
  """
  def transaction_status_class(status) do
    case status do
      "completed" -> "bg-green-100 text-green-800"
      "success" -> "bg-green-100 text-green-800"
      "pending" -> "bg-blue-100 text-blue-800"
      "processing" -> "bg-blue-100 text-blue-800"
      "failed" -> "bg-red-100 text-red-800"
      "cancelled" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  @doc """
  Returns the appropriate CSS class for callback type display.
  """
  def callback_type_class(type) do
    case type do
      "stk_push" -> "bg-purple-100 text-purple-800"
      "c2b_validation" -> "bg-blue-100 text-blue-800"
      "c2b_confirmation" -> "bg-indigo-100 text-indigo-800"
      "transaction_status" -> "bg-yellow-100 text-yellow-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  @doc """
  Formats a callback type for display.
  """
  def format_callback_type(type) do
    case type do
      "stk_push" -> "STK Push"
      "c2b_validation" -> "C2B Validation"
      "c2b_confirmation" -> "C2B Confirmation"
      "transaction_status" -> "Transaction Status"
      _ -> String.replace(type || "", "_", " ") |> String.capitalize()
    end
  end

  @doc """
  Formats a date for display.
  """
  def format_date(nil), do: "-"

  def format_date(%DateTime{} = date) do
    Calendar.strftime(date, "%d %b %Y, %H:%M:%S")
  end

  def format_date(%NaiveDateTime{} = date) do
    Calendar.strftime(date, "%d %b %Y, %H:%M:%S")
  end

  def format_date(date), do: date

  @doc """
  Formats a date and time for display.
  """
  def format_date_time(nil), do: "-"

  def format_date_time(%DateTime{} = date) do
    Calendar.strftime(date, "%d %b %Y, %H:%M:%S")
  end

  def format_date_time(%NaiveDateTime{} = date) do
    Calendar.strftime(date, "%d %b %Y, %H:%M:%S")
  end

  def format_date_time(date), do: date

  @doc """
  Formats an amount for display.
  """
  def format_amount(nil), do: "-"

  def format_amount(amount) when is_float(amount) do
    "KES #{:erlang.float_to_binary(amount, decimals: 2)}"
  end

  def format_amount(amount) when is_integer(amount) do
    "KES #{amount}.00"
  end

  def format_amount(amount), do: "KES #{amount}"

  @doc """
  Formats JSON for display.
  """
  def format_json(nil), do: "No data available"

  def format_json(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, decoded} ->
        Jason.encode!(decoded, pretty: true)

      _ ->
        json
    end
  end

  def format_json(data) do
    case Jason.encode(data, pretty: true) do
      {:ok, encoded} -> encoded
      _ -> inspect(data)
    end
  end

  @doc """
  Masks sensitive data for display.
  """
  def mask_sensitive(nil), do: "-"

  def mask_sensitive(value) when is_binary(value) do
    cond do
      String.length(value) <= 4 ->
        String.duplicate("*", String.length(value))

      String.length(value) <= 8 ->
        "#{String.slice(value, 0, 2)}#{String.duplicate("*", String.length(value) - 4)}#{String.slice(value, -2, 2)}"

      true ->
        "#{String.slice(value, 0, 4)}#{String.duplicate("*", String.length(value) - 8)}#{String.slice(value, -4, 4)}"
    end
  end

  def mask_sensitive(value), do: value

  @doc """
  Returns the environment name with appropriate styling.
  """
  def environment_badge(env) do
    case env do
      "production" ->
        content_tag(:span, "Production",
          class:
            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800"
        )

      "sandbox" ->
        content_tag(:span, "Sandbox",
          class:
            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800"
        )

      _ ->
        content_tag(:span, env,
          class:
            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800"
        )
    end
  end

  @doc """
  Returns pagination links for transaction listing.
  """
  def pagination_links(conn, params, total_pages) do
    current_page = Map.get(params, "page", "1") |> String.to_integer()

    content_tag :div,
      class: "flex items-center justify-between border-t border-gray-200 px-4 py-3 sm:px-6" do
      [
        content_tag(:div, class: "flex flex-1 justify-between sm:hidden") do
          [
            if current_page > 1 do
              link("Previous",
                to:
                  Routes.mpesa_admin_path(
                    conn,
                    :transactions,
                    Map.put(params, "page", current_page - 1)
                  ),
                class:
                  "relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              )
            else
              content_tag(:span, "Previous",
                class:
                  "relative inline-flex items-center rounded-md border border-gray-300 bg-gray-100 px-4 py-2 text-sm font-medium text-gray-500"
              )
            end,
            if current_page < total_pages do
              link("Next",
                to:
                  Routes.mpesa_admin_path(
                    conn,
                    :transactions,
                    Map.put(params, "page", current_page + 1)
                  ),
                class:
                  "relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              )
            else
              content_tag(:span, "Next",
                class:
                  "relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-gray-100 px-4 py-2 text-sm font-medium text-gray-500"
              )
            end
          ]
        end,
        content_tag(:div, class: "hidden sm:flex sm:flex-1 sm:items-center sm:justify-between") do
          [
            content_tag(:div) do
              content_tag(:p, class: "text-sm text-gray-700") do
                [
                  "Showing ",
                  content_tag(:span, class: "font-medium") do
                    "#{(current_page - 1) * 20 + 1}"
                  end,
                  " to ",
                  content_tag(:span, class: "font-medium") do
                    "#{min(current_page * 20, total_pages * 20)}"
                  end,
                  " of ",
                  content_tag(:span, class: "font-medium") do
                    "#{total_pages * 20}"
                  end,
                  " results"
                ]
              end
            end,
            content_tag(:div) do
              content_tag(:nav,
                class: "isolate inline-flex -space-x-px rounded-md shadow-sm",
                "aria-label": "Pagination"
              ) do
                [
                  if current_page > 1 do
                    link to:
                           Routes.mpesa_admin_path(
                             conn,
                             :transactions,
                             Map.put(params, "page", current_page - 1)
                           ),
                         class:
                           "relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0" do
                      content_tag(:span, "Previous", class: "sr-only")
                    end
                  else
                    content_tag(:span,
                      class:
                        "relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 focus:outline-offset-0"
                    ) do
                      content_tag(:span, "Previous", class: "sr-only")
                    end
                  end,
                  for page <- max(1, current_page - 2)..min(total_pages, current_page + 2) do
                    if page == current_page do
                      content_tag(:span, "#{page}",
                        class:
                          "relative z-10 inline-flex items-center bg-indigo-600 px-4 py-2 text-sm font-semibold text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                      )
                    else
                      link("#{page}",
                        to:
                          Routes.mpesa_admin_path(
                            conn,
                            :transactions,
                            Map.put(params, "page", page)
                          ),
                        class:
                          "relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
                      )
                    end
                  end,
                  if current_page < total_pages do
                    link to:
                           Routes.mpesa_admin_path(
                             conn,
                             :transactions,
                             Map.put(params, "page", current_page + 1)
                           ),
                         class:
                           "relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0" do
                      content_tag(:span, "Next", class: "sr-only")
                    end
                  else
                    content_tag(:span,
                      class:
                        "relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 focus:outline-offset-0"
                    ) do
                      content_tag(:span, "Next", class: "sr-only")
                    end
                  end
                ]
              end
            end
          ]
        end
      ]
    end
  end
end
