defmodule Clinicpro.Accounts.Doctor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "doctors" do
    field :email, :string
    field :clinic_id, :string
    field :name, :string
    field :specialization, :string
    field :password_hash, :string
    field :last_login_at, :utc_datetime
    field :login_count, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [
      :email,
      :clinic_id,
      :name,
      :specialization,
      :password_hash,
      :last_login_at,
      :login_count
    ])
    |> validate_required([:email, :clinic_id])
    |> unique_constraint([:email, :clinic_id], name: :doctors_email_clinic_id_index)
  end
end
