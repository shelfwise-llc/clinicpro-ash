defmodule Clinicpro.Accounts.LegacyUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :role, :string, default: "user"
    field :clinic_id, :binary_id

    timestamps()
  end

  @doc """
  A user changeset for registration.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation, :role, :clinic_id])
    |> validate_email()
    |> validate_password()
    |> validate_confirmation(:password)
    |> validate_required([:clinic_id], message: "Clinic must be specified")
    |> hash_password()
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_confirmation(:password)
    |> validate_password()
    |> hash_password()
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  Confirms a user by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Clinicpro.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    # Examples of additional password validation:
    |> validate_format(:password, ~r/[a-z]/,
      message: "must have at least one lowercase character"
    )
    |> validate_format(:password, ~r/[A-Z]/,
      message: "must have at least one uppercase character"
    )
    |> validate_format(:password, ~r/[0-9]/, message: "must have at least one digit")
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
      |> delete_change(:password_confirmation)
    else
      changeset
    end
  end
end
