defmodule ClinicproWeb.Auth.Pipeline do
  @moduledoc """
  Authentication pipeline for Guardian JWT authentication.

  This pipeline handles JWT token verification, loading the resource from the token,
  and storing it in the connection for use in controllers and views.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :clinicpro,
    error_handler: ClinicproWeb.Auth.ErrorHandler,
    module: Clinicpro.Auth.Guardian

  # If there is a session token, restrict it to an access token and validate it
  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  # If there is an authorization header, restrict it to an access token and validate it
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  # Load the user if either of the verifications worked
  plug Guardian.Plug.LoadResource, allow_blank: true
end
