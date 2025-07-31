defmodule Clinicpro.Accounts.PatientValue do
  @moduledoc """
  Value object representing a patient.
  """

  defstruct [
    :id,
    :name,
    :email,
    :phone,
    :date_of_birth,
    :status,
    :active,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new patient value object.
  """
  def new(attrs) do
    %__MODULE__{
      id: attrs[:id] || attrs["id"],
      name: attrs[:name] || attrs["name"],
      email: attrs[:email] || attrs["email"],
      phone: attrs[:phone] || attrs["phone"],
      date_of_birth: attrs[:date_of_birth] || attrs["date_of_birth"],
      status: attrs[:status] || attrs["status"],
      active: attrs[:active] || attrs["active"] || false,
      created_at: attrs[:created_at] || attrs["created_at"],
      updated_at: attrs[:updated_at] || attrs["updated_at"]
    }
  end

  @doc """
  Converts a patient struct to a JSON-serializable map.
  """
  def to_json(patient) do
    %{
      id: patient.id,
      name: patient.name,
      email: patient.email,
      phone: patient.phone,
      date_of_birth: patient.date_of_birth,
      status: patient.status,
      active: patient.active
    }
  end

  @doc """
  Validates patient attributes.
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
