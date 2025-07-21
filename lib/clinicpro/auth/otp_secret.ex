defmodule Clinicpro.Auth.OTPSecret do
  use Ecto.Schema
  import Ecto.Changeset
  alias Clinicpro.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "otp_secrets" do
    field :secret, :string
    field :active, :boolean, default: true
    field :last_used_at, :utc_datetime
    field :expires_at, :utc_datetime

    # Multi-tenant fields
    belongs_to :patient, Clinicpro.Patient
    belongs_to :clinic, Clinicpro.Clinic

    timestamps()
  end

  @doc """
  Creates a changeset for OTP secrets.
  """
  def changeset(otp_secret, attrs) do
    otp_secret
    |> cast(attrs, [:secret, :active, :last_used_at, :expires_at, :patient_id, :clinic_id])
    |> validate_required([:secret, :patient_id, :clinic_id])
    |> foreign_key_constraint(:patient_id)
    |> foreign_key_constraint(:clinic_id)
  end

  @doc """
  Generates a new OTP secret for a patient in a specific clinic.
  """
  def generate_for_patient(patient_id, clinic_id) do
    # Generate a random secret
    secret = :crypto.strong_rand_bytes(20) |> Base.encode32()

    # Set expiration to 30 days from now
    expires_at = DateTime.utc_now() |> DateTime.add(30 * 24 * 60 * 60, :second)

    # Create a new OTP secret
    %__MODULE__{}
    |> changeset(%{
      secret: secret,
      active: true,
      expires_at: expires_at,
      patient_id: patient_id,
      clinic_id: clinic_id
    })
    |> Repo.insert()
  end

  @doc """
  Deactivates all existing OTP secrets for a patient in a specific clinic.
  """
  def deactivate_for_patient(patient_id, clinic_id) do
    import Ecto.Query

    from(s in __MODULE__,
      where: s.patient_id == ^patient_id and
             s.clinic_id == ^clinic_id and
             s.active == true
    )
    |> Repo.update_all(set: [active: false])
  end

  @doc """
  Finds an active OTP secret for a patient in a specific clinic.
  """
  def find_active_for_patient(patient_id, clinic_id) do
    import Ecto.Query

    from(s in __MODULE__,
      where: s.patient_id == ^patient_id and
             s.clinic_id == ^clinic_id and
             s.active == true and
             (is_nil(s.expires_at) or s.expires_at > ^DateTime.utc_now())
    )
    |> Repo.one()
  end

  @doc """
  Updates the last_used_at timestamp for an OTP secret.
  """
  def mark_as_used(otp_secret_id) do
    import Ecto.Query

    from(s in __MODULE__, where: s.id == ^otp_secret_id)
    |> Repo.update_all(set: [last_used_at: DateTime.utc_now()])
  end
end
