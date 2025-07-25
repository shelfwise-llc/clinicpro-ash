defmodule Mix.Tasks.Assets.Deploy do
  @shortdoc "Deploy app assets for production"
  @moduledoc """
  Deploys the application assets for production.
  This task will compile all assets using esbuild and tailwind.
  """
  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Mix.shell().info("==> Compiling assets with esbuild")
    Mix.Task.run("esbuild", ["default", "--minify"])

    Mix.shell().info("==> Compiling CSS with tailwind")
    Mix.Task.run("tailwind", ["default", "--minify"])

    Mix.shell().info("==> Digesting static assets")
    Mix.Task.run("phx.digest")
  end
end
