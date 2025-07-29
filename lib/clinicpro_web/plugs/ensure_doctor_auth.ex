defmodule ClinicproWeb.Plugs.EnsureDoctorAuth do
  @moduledoc """
  Plug to ensure doctor is authenticated before accessing protected routes.
  """
  
  import Plug.Conn
  import Phoenix.Controller
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    doctor_id = get_session(conn, :doctor_id)
    
    if doctor_id do
      # Doctor is authenticated, continue
      assign(conn, :current_doctor_id, doctor_id)
    else
      # Doctor not authenticated, redirect to login
      conn
      |> put_flash(:error, "Please log in to access this page.")
      |> redirect(to: "/doctor/login")
      |> halt()
    end
  end
end
