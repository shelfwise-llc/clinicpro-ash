defmodule ClinicproWeb.Plugs.EnsurePatientAuth do
  @moduledoc """
  This plug ensures that a patient is authenticated.
  If not, it redirects to the login page.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias ClinicproWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    if patient_id = get_session(conn, :patient_id) do
      # Patient is authenticated
      clinic_id = get_session(conn, :clinic_id)

      conn
      |> assign(:current_patient_id, patient_id)
      |> assign(:current_clinic_id, clinic_id)
    else
      # Patient is not authenticated
      conn
      |> put_flash(:error, "You must be logged in to access this page")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
