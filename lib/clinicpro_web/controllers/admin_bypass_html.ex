defmodule ClinicproWeb.AdminBypassHTML do
  use ClinicproWeb, :html

  embed_templates "admin_bypass_html/*"

  # Keep only the necessary import for components
  import Phoenix.Component

  # Keep Phoenix.HTML.Form for form helper functions
  # # import Phoenix.HTML.Form, only: []

  # Explicitly define form helper functions that are needed by templates
  def select(form, field, options, _opts \\ []),
    do: Phoenix.HTML.Form.select(form, field, options, _opts)

  def date_input(form, field, _opts \\ []), do: Phoenix.HTML.Form.date_input(form, field, _opts)
  def number_input(form, field, opts \\ []), do: Phoenix.HTML.Form.number_input(form, field, opts)

  # Keep helper functions for formatting
  def format_percentage(value, precision \\ 1) do
    formatted = :erlang.float_to_binary(value / 1, decimals: precision)
    "#{formatted}%"
  end

  def format_date(nil), do: ""

  def format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  def format_time(nil), do: ""

  def format_time(%Time{} = time) do
    Calendar.strftime(time, "%I:%M %p")
  end
end
