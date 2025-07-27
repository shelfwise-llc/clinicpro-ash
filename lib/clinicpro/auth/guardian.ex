defmodule Clinicpro.Auth.Guardian do
  use Guardian, otp_app: :clinicpro

  alias Clinicpro.Accounts.AuthUser

  @doc """
  Used by Guardian to retrieve a resource from a token subject.
  """
  def subject_for_token(%{id: id}, _claims) do
    sub = to_string(id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  @doc """
  Used by Guardian to build a resource from a token.
  """
  def resource_from_claims(%{"sub" => id}) do
    # Implement user lookup based on the ID from the token
    case Clinicpro.Accounts.get_auth_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Adds custom claims to the JWT token.

  Specifically adds:
  - role: The user's role for role-based access control
  - clinic_id: The user's clinic_id for multi-tenant isolation
  """
  def build_claims(claims, resource, _opts) do
    claims =
      claims
      |> Map.put("role", resource.role)
      |> Map.put("clinic_id", resource.clinic_id)

    {:ok, claims}
  end
end
