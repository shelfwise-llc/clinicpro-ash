defmodule Clinicpro.Auth.GuardianTest do
  use Clinicpro.DataCase
  import Mox

  alias Clinicpro.Auth.Guardian
  alias Clinicpro.Accounts.AuthUser

  describe "subject_for_token/2" do
    test "returns the subject when given a valid user" do
      user = %AuthUser{id: Ecto.UUID.generate()}
      assert {:ok, subject} = Guardian.subject_for_token(user, %{})
      assert subject == user.id
    end

    test "returns error when given an invalid resource" do
      assert {:error, :invalid_resource} = Guardian.subject_for_token(%{}, %{})
    end
  end

  describe "resource_from_claims/1" do
    test "returns the user when given valid claims with a valid user ID" do
      user = %AuthUser{id: Ecto.UUID.generate()}

      # Mock the Accounts.get_auth_user/1 function
      expect(Clinicpro.Accounts, :get_auth_user, fn id ->
        assert id == user.id
        user
      end)

      assert {:ok, returned_user} = Guardian.resource_from_claims(%{"sub" => user.id})
      assert returned_user == user
    end

    test "returns error when user is not found" do
      user_id = Ecto.UUID.generate()

      # Mock the Accounts.get_auth_user/1 function to return nil
      expect(Clinicpro.Accounts, :get_auth_user, fn id ->
        assert id == user_id
        nil
      end)

      assert {:error, :resource_not_found} = Guardian.resource_from_claims(%{"sub" => user_id})
    end

    test "returns error when claims are invalid" do
      assert {:error, :invalid_claims} = Guardian.resource_from_claims(%{})
    end
  end

  describe "build_claims/3" do
    test "adds role and clinic_id to claims" do
      user = %AuthUser{
        id: Ecto.UUID.generate(),
        role: "admin",
        clinic_id: Ecto.UUID.generate()
      }

      claims = %{}

      assert {:ok, updated_claims} = Guardian.build_claims(claims, user, %{})
      assert updated_claims["role"] == "admin"
      assert updated_claims["clinic_id"] == user.clinic_id
    end
  end

  # Setup for mocking
  setup do
    Mox.stub_with(Clinicpro.AccountsMock, Clinicpro.Accounts)
    :ok
  end
end
