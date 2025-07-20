defmodule ClinicproWeb.AdminBypassHTML do
  use ClinicproWeb, :html

  # Import Phoenix form helpers and core components
  import Phoenix.HTML.Form
  import Phoenix.HTML
  import ClinicproWeb.CoreComponents

  embed_templates "admin_bypass_html/*"

  # Form components
  # These are embedded directly from the template files in admin_bypass_html/ directory
  
  # Additional form helpers not imported by default
  def telephone_input(form, field, opts \\ []), do: Phoenix.HTML.Form.telephone_input(form, field, opts)
  def checkbox(form, field, opts \\ []), do: Phoenix.HTML.Form.checkbox(form, field, opts)
  def submit(value, opts \\ []), do: Phoenix.HTML.Form.submit(value, opts)
  def content_tag(tag, content_or_attrs_or_void, attrs_or_content_or_void \\ []) do
    Phoenix.HTML.content_tag(tag, content_or_attrs_or_void, attrs_or_content_or_void)
  end
  
  # Helper functions
  def format_date(nil), do: ""
  def format_date(%Date{} = date), do: Calendar.strftime(date, "%B %d, %Y")
  
  def format_time(nil), do: ""
  def format_time(%Time{} = time), do: Calendar.strftime(time, "%I:%M %p")





end
