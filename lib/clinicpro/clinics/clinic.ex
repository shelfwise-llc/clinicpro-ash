defmodule Clinicpro.Clinics.Clinic do
  @moduledoc """
  Multi-tenant clinic entity with SRP compliance.
  Each clinic operates as an independent unit.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "clinics" do
    field :name, :string
    field :subdomain, :string
    field :settings, :map, default: %{}
    field :payment_config, :map, default: %{}
    
    # Multi-tenant isolation
    has_many :patients, Clinicpro.Accounts.Patient
    has_many :doctors, Clinicpro.Accounts.Doctor
    has_many :appointments, Clinicpro.Appointments.Appointment
    has_many :payments, Clinicpro.Payments.Payment
    
    timestamps()
  end

  def changeset(clinic, attrs) do
    clinic
    |> cast(attrs, [:name, :subdomain, :settings, :payment_config])
    |> validate_required([:name, :subdomain])
    |> unique_constraint(:subdomain)
  end
end
