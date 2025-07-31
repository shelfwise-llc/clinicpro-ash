defmodule Clinicpro.Accounts.Admin do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins" do
    field :email, :string
    field :clinic_id, :string
    field :name, :string
    field :role, :string, default: "admin"
    field :password_hash, :string
    field :last_login_at, :utc_datetime
    field :login_count, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(admin, attrs) do
    admin
    |> cast(attrs, [
      :email,
      :clinic_id,
      :name,
      :role,
      :password_hash,
      :last_login_at,
      :login_count
    ])
    |> validate_required([:email, :clinic_id])
    |> unique_constraint([:email, :clinic_id], name: :admins_email_clinic_id_index)
  end
end
