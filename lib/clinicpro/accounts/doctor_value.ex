defmodule Clinicpro.Accounts.DoctorValue do
  @moduledoc """
  Value object representing a doctor.
  """

  defstruct [
    :id,
    :name,
    :email,
    :specialty,
    :phone,
    :status,
    :active,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new doctor value object.
  """
  def new(attrs) do
    %__MODULE__{
      id: attrs[:id] || attrs["id"],
      name: attrs[:name] || attrs["name"],
      email: attrs[:email] || attrs["email"],
      specialty: attrs[:specialty] || attrs["specialty"],
      phone: attrs[:phone] || attrs["phone"],
      status: attrs[:status] || attrs["status"],
      active: attrs[:active] || attrs["active"] || false,
      created_at: attrs[:created_at] || attrs["created_at"],
      updated_at: attrs[:updated_at] || attrs["updated_at"]
    }
  end

  @doc """
  Converts a doctor struct to a JSON-serializable map.
  """
  def to_json(doctor) do
    %{
      id: doctor.id,
      name: doctor.name,
      email: doctor.email,
      specialty: doctor.specialty,
      phone: doctor.phone,
      status: doctor.status,
      active: doctor.active
    }
  end

  @doc """
  Validates doctor attributes.
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
