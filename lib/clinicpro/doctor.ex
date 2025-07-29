defmodule Clinicpro.Doctor do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Clinicpro.Repo
  alias Clinicpro.Appointment

  schema "doctors" do
    field :active, :boolean, default: true
    field :name, :string
    field :status, :string, default: "Active"
    field :email, :string
    field :specialty, :string
    field :phone, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    has_many :appointments, Appointment

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a doctor.
  """
  def changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [:name, :specialty, :email, :phone, :status, :active, :password])
    |> validate_required([:name, :specialty, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
    |> validate_password()
    |> maybe_hash_password()
  end

  defp validate_password(changeset) do
    password = get_change(changeset, :password)
    
    if password do
      case Clinicpro.Auth.PasswordValidator.validate_password(password) do
        {:ok, _} -> changeset
        {:error, message} -> add_error(changeset, :password, message)
      end
    else
      changeset
    end
  end

  defp maybe_hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, hash_password(password))
  end

  defp maybe_hash_password(changeset), do: changeset

  defp hash_password(password) do
    # Simple hash for demo - in production use bcrypt or similar
    :crypto.hash(:sha256, password) |> Base.encode16() |> String.downcase()
  end

  @doc """
  Returns a changeset for tracking doctor changes.
  """
  def change(%__MODULE__{} = doctor, attrs \\ %{}) do
    changeset(doctor, attrs)
  end

  @doc """
  Gets a doctor by ID.
  """
  def get(id), do: Repo.get(__MODULE__, id)

  @doc """
  Gets a doctor by ID with preloaded appointments.
  """
  def get_with_appointments(id) do
    __MODULE__
    |> Repo.get(id)
    |> Repo.preload([:appointments])
  end

  @doc """
  Lists all _doctors.
  """
  def list do
    Repo.all(__MODULE__)
  end

  @doc """
  Lists _doctors with optional filtering.

  ## Options

  * `:limit` - Limits the number of results
  * `:active` - Filter by active status
  * `:name` - Filter by name (partial match)
  * `:email` - Filter by email (partial match)
  * `:specialty` - Filter by specialty
  """
  def list(_opts) do
    __MODULE__
    |> filter_byactive(_opts)
    |> filter_by_name(_opts)
    |> filter_by_email(_opts)
    |> filter_by_specialty(_opts)
    |> limit_query(_opts)
    |> Repo.all()
  end

  @doc """
  Lists all active _doctors.
  """
  def listactive do
    __MODULE__
    |> where(active: true)
    |> Repo.all()
  end

  # Private filter functions
  defp filter_byactive(query, %{active: active}) when is_boolean(active),
    do: where(query, [d], d.active == ^active)

  defp filter_byactive(query, _unused), do: query

  defp filter_by_name(query, %{name: name}) when is_binary(name) and name != "",
    do: where(query, [d], ilike(d.name, ^"%#{name}%"))

  defp filter_by_name(query, _unused), do: query

  defp filter_by_email(query, %{email: email}) when is_binary(email) and email != "",
    do: where(query, [d], ilike(d.email, ^"%#{email}%"))

  defp filter_by_email(query, _unused), do: query

  defp filter_by_specialty(query, %{specialty: specialty})
       when is_binary(specialty) and specialty != "",
       do: where(query, [d], d.specialty == ^specialty)

  defp filter_by_specialty(query, _unused), do: query

  defp limit_query(query, %{limit: limit}) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp limit_query(query, _unused), do: query

  @doc """
  Creates a new doctor.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a doctor.
  """
  def update(doctor, attrs) do
    doctor
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a doctor.
  """
  def delete(doctor) do
    Repo.delete(doctor)
  end

  @doc """
  Authenticates a doctor with email and password.
  """
  def authenticate(email, password) do
    case Repo.get_by(__MODULE__, email: email) do
      nil ->
        {:error, "Invalid email or password"}

      doctor ->
        if verify_password(password, doctor.password_hash) do
          {:ok, doctor}
        else
          {:error, "Invalid email or password"}
        end
    end
  end

  defp verify_password(password, hash) do
    hash_password(password) == hash
  end
end
