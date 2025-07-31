defmodule Clinicpro.Accounts.AdminValue do
  @moduledoc """
  Value object representing an admin.
  """

  defstruct [
    :id,
    :name,
    :email,
    :role,
    :active,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new admin value object.
  """
  def new(attrs) do
    %__MODULE__{
      id: attrs[:id] || attrs["id"],
      name: attrs[:name] || attrs["name"],
      email: attrs[:email] || attrs["email"],
      role: attrs[:role] || attrs["role"] || "admin",
      active: attrs[:active] || attrs["active"] || false,
      created_at: attrs[:created_at] || attrs["created_at"],
      updated_at: attrs[:updated_at] || attrs["updated_at"]
    }
  end

  @doc """
  Converts an admin struct to a JSON-serializable map.
  """
  def to_json(admin) do
    %{
      id: admin.id,
      name: admin.name,
      email: admin.email,
      role: admin.role,
      active: admin.active
    }
  end

  @doc """
  Validates admin attributes.
  """
  def validate(attrs) do
    errors = []

    errors =
      if blank?(attrs[:name] || attrs["name"]),
        do: [{:name, "can't be blank"} | errors],
        else: errors

    errors =
      if blank?(attrs[:email] || attrs["email"]),
        do: [{:email, "can't be blank"} | errors],
        else: errors

    if Enum.empty?(errors) do
      {:ok, new(attrs)}
    else
      {:error, errors}
    end
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false
end
