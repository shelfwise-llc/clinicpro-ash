defmodule ClinicproWeb.AdminHTML do
  use ClinicproWeb, :html
  import Phoenix.Controller, only: [get_flash: 2]
  # Import CSRF token function directly
  def get_csrf_token do
    Phoenix.Controller.get_csrf_token()
  end

  embed_templates "admin_html/*"
end
