defmodule Clinicpro.Accounts.Patient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patients" do
    field :email, :string
    field :clinic_id, :string
    field :name, :string
    field :phone, :string
    field :magic_link_token, :string
    field :token_expires_at, :utc_datetime
    field :last_login_at, :utc_datetime
    field :login_count, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :email,
      :clinic_id,
      :name,
      :phone,
      :magic_link_token,
      :token_expires_at,
      :last_login_at,
      :login_count
    ])
    |> validate_required([:email, :clinic_id])
    |> unique_constraint([:email, :clinic_id], name: :patients_email_clinic_id_index)
  end
end
