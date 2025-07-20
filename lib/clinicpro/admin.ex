defmodule Clinicpro.Admin do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo

  schema "admins" do
    field :active, :boolean, default: true
    field :name, :string
    field :email, :string
    field :role, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a new admin.
  """
  def changeset(admin, attrs) do
    admin
    |> cast(attrs, [:email, :name, :password, :password_confirmation, :role, :active])
    |> validate_required([:email, :name, :password, :role])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:password, min: 8, message: "should be at least 8 characters")
    |> validate_confirmation(:password, message: "does not match password")
    |> unique_constraint(:email)
    |> hash_password()
  end

  @doc """
  Creates a changeset for updating an admin.
  """
  def update_changeset(admin, attrs) do
    admin
    |> cast(attrs, [:name, :role, :active])
    |> validate_required([:name, :role])
  end

  @doc """
  Creates a changeset for changing an admin's password.
  """
  def password_changeset(admin, attrs) do
    admin
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8, message: "should be at least 8 characters")
    |> validate_confirmation(:password, message: "does not match password")
    |> hash_password()
  end

  @doc """
  Hashes the password in a changeset if one is present.
  """
  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
      _ ->
        changeset
    end
  end

  @doc """
  Authenticates an admin by email and password.
  Returns {:ok, admin} if valid, {:error, reason} otherwise.
  """
  def authenticate(email, password) do
    admin = Repo.get_by(__MODULE__, email: email)

    cond do
      admin && Bcrypt.verify_pass(password, admin.password_hash) && admin.active ->
        {:ok, admin}
      admin && !admin.active ->
        {:error, "Account is inactive"}
      admin ->
        {:error, "Invalid password"}
      true ->
        # Prevent timing attacks by simulating password check
        Bcrypt.no_user_verify()
        {:error, "Invalid email or password"}
    end
  end

  @doc """
  Gets an admin by ID.
  """
  def get(id), do: Repo.get(__MODULE__, id)

  @doc """
  Lists all admins.
  """
  def list, do: Repo.all(__MODULE__)

  @doc """
  Creates a new admin.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an admin.
  """
  def update(admin, attrs) do
    admin
    |> update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates an admin's password.
  """
  def update_password(admin, attrs) do
    admin
    |> password_changeset(attrs)
    |> Repo.update()
  end
end
