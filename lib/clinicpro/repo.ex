defmodule Clinicpro.Repo do
  use Ecto.Repo,
    otp_app: :clinicpro,
    adapter: Ecto.Adapters.Postgres
end
