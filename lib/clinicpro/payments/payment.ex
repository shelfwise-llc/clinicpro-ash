defmodule Clinicpro.Payments.Payment do
  @moduledoc """
  Multi-tenant payment entity supporting Paystack and M-Pesa.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "payments" do
    field :clinic_id, :string
    field :customer_email, :string
    field :customer_phone, :string
    field :amount, :decimal
    field :currency, :string, default: "USD"
    field :gateway, :string  # "paystack" or "mpesa"
    field :reference, :string
    field :status, :string, default: "pending"
    field :gateway_response, :map, default: %{}
    field :metadata, :map, default: %{}

    timestamps()
  end

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [
      :clinic_id,
      :customer_email,
      :customer_phone,
      :amount,
      :currency,
      :gateway,
      :reference,
      :status,
      :gateway_response,
      :metadata
    ])
    |> validate_required([:clinic_id, :amount, :gateway, :reference])
    |> validate_inclusion(:gateway, ["paystack", "mpesa"])
    |> validate_inclusion(:status, ["pending", "success", "failed", "cancelled"])
    |> unique_constraint([:reference, :clinic_id])
  end
end
