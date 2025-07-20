defmodule Clinicpro.Utils.Slug do
  @moduledoc """
  Utility functions for generating slugs.

  This module provides a clean, reusable way to generate slugs from strings.
  """

  @doc """
  Generates a slug from a string by converting to lowercase and replacing spaces with hyphens.

  ## Examples

      iex> Clinicpro.Utils.Slug.generate("Hello World")
      "hello-world"

      iex> Clinicpro.Utils.Slug.generate("Special Clinic #123")
      "special-clinic-123"
  """
  @spec generate(String.t() | nil) :: String.t()
  def generate(nil), do: ""
  def generate(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/u, "")
    |> String.trim()
    |> String.replace(~r/\s+/, "-")
  end
end
