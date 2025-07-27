defmodule ClinicproWeb.Auth.EnsureClinicIsolation do
  @moduledoc """
  Plug to ensure clinic isolation in multi-tenant architecture.

  This plug enforces that users can only access resources belonging to their clinic,
  except for admin users who can access resources across clinics.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Clinicpro.Accounts.AuthUser

  @doc """
  Initialize the plug with options.
  """
  def init(opts), do: opts

  @doc """
  Call function for the plug.

  Verifies that the current user's clinic_id matches the clinic_id in the params,
  unless the user is an admin.
  """
  def call(conn, _opts) do
    user_clinic_id = get_user_clinic_id(conn)
    param_clinic_id = get_clinic_id_from_params(conn)
    user_role = get_user_role(conn)

    cond do
      # Admin users can access any clinic's resources
      user_role == "admin" ->
        conn

      # If no clinic_id in params, allow the request (non-clinic specific endpoint)
      is_nil(param_clinic_id) ->
        conn

      # If user's clinic_id matches param clinic_id, allow the request
      user_clinic_id == param_clinic_id ->
        conn

      # Otherwise, deny access
      true ->
        conn
        |> put_status(:forbidden)
        |> put_view(ClinicproWeb.ErrorView)
        |> render(:"403")
        |> halt()
    end
  end

  # Get the user's clinic_id from the connection
  defp get_user_clinic_id(conn) do
    case Guardian.Plug.current_resource(conn) do
      %AuthUser{clinic_id: clinic_id} -> clinic_id
      _ -> nil
    end
  end

  # Get the user's role from the connection
  defp get_user_role(conn) do
    case Guardian.Plug.current_resource(conn) do
      %AuthUser{role: role} -> role
      _ -> nil
    end
  end

  # Get the clinic_id from the request parameters
  defp get_clinic_id_from_params(conn) do
    conn.params["clinic_id"]
  end
end
