defmodule Clinicpro.Release do
  @moduledoc """
  Module for running migrations and seeds in a release environment.
  """
  @app :clinicpro

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _unused, _unused} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _unused, _unused} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _unused, _unused} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          seed_path = Application.app_dir(:clinicpro, "priv/repo/seeds.exs")

          if File.exists?(seed_path) do
            Code.eval_file(seed_path)
          end
        end)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
