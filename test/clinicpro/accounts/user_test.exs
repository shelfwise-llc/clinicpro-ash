defmodule Clinicpro.Accounts.UserTest do
  @moduledoc """
  Tests for the User resource in the Accounts context.
  """
  use Clinicpro.DataCase, async: true
  alias Clinicpro.Accounts
  alias Clinicpro.Accounts.User

  describe "user registration" do
    test "can register a user with valid attributes" do
      attrs = %{
        email: "test@example.com",
        first_name: "Test",
        last_name: "User",
        phone_number: "+1234567890"
      }

      assert {:ok, %User{} = user} = Accounts.register(attrs)
      assert user.email == "test@example.com"
      assert user.first_name == "Test"
      assert user.last_name == "User"
      assert user.phone_number == "+1234567890"
      # Username should be synchronized with email
      assert user.username == "test@example.com"
    end

    test "cannot register a user with invalid email" do
      attrs = %{
        email: "invalid-email",
        first_name: "Test",
        last_name: "User"
      }

      assert {:error, changeset} = Accounts.register(attrs)
      assert "has invalid format" in errors_on(changeset).email
    end

    test "cannot register a user with missing required fields" do
      # Missing first_name and last_name
      attrs = %{
        email: "test@example.com"
      }

      assert {:error, changeset} = Accounts.register(attrs)
      assert "can't be blank" in errors_on(changeset).first_name
      assert "can't be blank" in errors_on(changeset).last_name
    end

    test "cannot register a user with duplicate email" do
      attrs = %{
        email: "test@example.com",
        first_name: "Test",
        last_name: "User"
      }

      assert {:ok, %User{}} = Accounts.register(attrs)
      assert {:error, changeset} = Accounts.register(attrs)
      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "magic link authentication" do
    test "can generate a magic link token for a registered user" do
      # First register a user
      attrs = %{
        email: "test@example.com",
        first_name: "Test",
        last_name: "User"
      }
      
      assert {:ok, %User{} = user} = Accounts.register(attrs)
      
      # Now request a magic link
      assert {:ok, _token} = Accounts.magic_link_request(%{"email" => "test@example.com"})
    end

    test "magic link request fails for non-existent user" do
      assert {:error, _reason} = Accounts.magic_link_request(%{"email" => "nonexistent@example.com"})
    end
  end
end
