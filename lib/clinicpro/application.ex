defmodule Clinicpro.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClinicproWeb.Telemetry,
      Clinicpro.Repo,
      {DNSCluster, query: Application.get_env(:clinicpro, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Clinicpro.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Clinicpro.Finch},
      # Start a worker by calling: Clinicpro.Worker.start_link(arg)
      # {Clinicpro.Worker, arg},
      # Start to serve requests, typically the last entry
      ClinicproWeb.Endpoint
    ]

    # Initialize OTP rate limiter
    Clinicpro.Auth.OTPRateLimiter.init()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Clinicpro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClinicproWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
