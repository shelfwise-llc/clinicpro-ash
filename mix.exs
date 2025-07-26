defmodule Clinicpro.MixProject do
  use Mix.Project

  def project do
    [
      app: :clinicpro,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # Coveralls configuration
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Clinicpro.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Phoenix Framework
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      # Downgraded to match ash_authentication_phoenix requirements
      {:phoenix_live_view, "~> 0.18"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      # Updated to match ash_authentication requirements
      {:finch, "~> 0.18.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},

      # Ash Framework
      {:ash, "~> 2.17"},
      {:ash_phoenix, "~> 1.3"},
      {:ash_postgres, "~> 1.3"},
      {:ash_json_api, "~> 0.34"},

      # Authentication
      {:ash_authentication, "~> 3.12.4"},
      # For secure password hashing
      {:argon2_elixir, "~> 3.0"},
      {:ash_authentication_phoenix, "~> 1.9"},
      # For admin authentication
      {:bcrypt_elixir, "~> 3.0"},

      # Admin Interface
      {:ash_admin, "~> 0.8"},

      # Development Tools
      {:live_debugger, "~> 0.1.0", only: :dev},

      # Testing Tools
      {:mox, "~> 1.0", only: :test},

      # HTTP Client for M-Pesa Integration
      {:httpoison, "~> 2.0"},

      # OTP Authentication
      {:nimble_totp, "~> 1.0"},

      # Google API Integration
      {:google_api_calendar, "~> 0.26.0"},
      {:goth, "~> 1.3"},

      # HTTP Client for API Integration
      {:oauth2, "~> 2.0"},
      {:ex_typesense, "~> 0.6.0"},

      # Code quality and test coverage
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
