defmodule Clinicpro.Patients do
  @moduledoc """
  Patients context for ClinicPro.

  This context handles patient management and medical records.
  """
  # Temporarily removed AshAuthentication for development
  use Ash.Api

  resources do
    resource(Clinicpro.Patients.Patient)
    resource(Clinicpro.Patients.MedicalRecord)
  end

  authorization do
    authorize(:by_default)
  end

  # Authentication configuration commented out for development
  # We're using the AuthPlaceholder module instead
  #
  # authentication do
  #   strategies do
  #     magic_link :magic_link do
  #       identity_field(:email)
  #       sender(Clinicpro.Accounts.MagicLinkSender)
  #       sign_in_tokens_enabled?(true)
  #     end
  #   end
  # end

  @doc """
  Gets a patient with their complete medical history.

  This function retrieves a patient and their associated medical records,
  including past appointments. It requires authentication and proper authorization.

  ## Examples

      iex> get_patient_with_history(patient_id, auth_token)
      {:ok, %Patient{...}}

  """
  def get_patient_with_history(patient_id, auth_token) do
    require Ash.Query

    Clinicpro.Patients.Patient
    |> Ash.Query.filter(Ash.Query.expr(id == ^patient_id))
    |> Ash.Query.load([:medical_records, :appointments])
    |> Ash.read_one(actor: auth_token.user)
  end
end
