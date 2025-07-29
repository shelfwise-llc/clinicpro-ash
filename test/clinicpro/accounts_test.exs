defmodule Clinicpro.AccountsTest do
  use Clinicpro.DataCase

  alias Clinicpro.Accounts
  alias Clinicpro.Accounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end

    test "returns nil if the email does not exist" do
      assert is_nil(Accounts.get_user_by_email("unknown@example.com"))
    end
  end

  describe "get_user_by_email_and_clinic/2" do
    test "returns the user if the email and clinic_id match" do
      %{id: id, clinic_id: clinic_id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email_and_clinic(user.email, clinic_id)
    end

    test "returns nil if the email exists but clinic_id doesn't match" do
      user = user_fixture()
      different_clinic_id = Ecto.UUID.generate()
      assert is_nil(Accounts.get_user_by_email_and_clinic(user.email, different_clinic_id))
    end

    test "returns nil if the email does not exist" do
      clinic_id = Ecto.UUID.generate()
      assert is_nil(Accounts.get_user_by_email_and_clinic("unknown@example.com", clinic_id))
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"],
               clinic_id: ["Clinic must be specified"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Accounts.register_user(%{
          email: "not valid",
          password: "short",
          clinic_id: Ecto.UUID.generate()
        })

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: [
                 "must have at least one lowercase character",
                 "must have at least one uppercase character",
                 "must have at least one digit"
               ]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.register_user(%{
          email: too_long,
          password: too_long,
          clinic_id: Ecto.UUID.generate()
        })

      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()

      {:error, changeset} =
        Accounts.register_user(%{
          email: email,
          password: "valid_password",
          clinic_id: Ecto.UUID.generate()
        })

      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} =
        Accounts.register_user(%{
          email: String.upcase(email),
          password: "valid_password",
          clinic_id: Ecto.UUID.generate()
        })

      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      clinic_id = Ecto.UUID.generate()

      {:ok, user} =
        Accounts.register_user(%{email: email, password: "valid_password", clinic_id: clinic_id})

      assert user.email == email
      assert user.clinic_id == clinic_id
      assert is_binary(user.password_hash)
      assert is_nil(user.password)
    end
  end

  describe "authenticate_user_by_email_password/2" do
    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert {:ok, %User{id: ^id}} =
               Accounts.authenticate_user_by_email_password(user.email, valid_user_password())
    end

    test "returns error if the email is not registered" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user_by_email_password("unknown@example.com", "hello world!")
    end

    test "returns error if the password is not valid" do
      user = user_fixture()

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user_by_email_password(user.email, "invalid")
    end

    test "respects clinic_id when provided" do
      %{id: id, clinic_id: clinic_id} = user = user_fixture()

      assert {:ok, %User{id: ^id}} =
               Accounts.authenticate_user_by_email_password(user.email, valid_user_password(),
                 clinic_id: clinic_id
               )

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user_by_email_password(user.email, valid_user_password(),
                 clinic_id: Ecto.UUID.generate()
               )
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.create_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "returns nil if token is invalid" do
      assert is_nil(Accounts.get_user_by_session_token("invalid"))
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.create_session_token(user)
      assert Accounts.delete_session_token(token) == :ok
      assert is_nil(Accounts.get_user_by_session_token(token))
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "returns nil with invalid token" do
      assert is_nil(Accounts.get_user_by_reset_password_token("invalid"))
    end

    test "returns nil if token expired", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert is_nil(Accounts.get_user_by_reset_password_token(token))
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "short",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "must have at least one lowercase character",
                 "must have at least one uppercase character",
                 "must have at least one digit"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "NewPassword123"})
      assert is_nil(updated_user.password)

      assert Accounts.authenticate_user_by_email_password(user.email, "NewPassword123") ==
               {:ok, updated_user}
    end
  end

  describe "verify_user_token/2" do
    test "returns user id with valid token and context" do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      assert {:ok, user_id} = Accounts.verify_user_token(token, "reset_password")
      assert user_id == user.id
    end

    test "returns error with invalid token" do
      assert {:error, :invalid_token} = Accounts.verify_user_token("invalid", "reset_password")
    end
  end

  # Helper functions

  defp extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  defp unique_user_email, do: "user#{System.unique_integer()}@example.com"
  defp valid_user_password, do: "Password123"

  defp user_fixture(attrs \\ %{}) do
    clinic = clinic_fixture()

    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password(),
        clinic_id: clinic.id
      })
      |> Accounts.register_user()

    user
  end

  defp clinic_fixture(attrs \\ %{}) do
    {:ok, clinic} =
      attrs
      |> Enum.into(%{
        name: "Test Clinic",
        address: "123 Test St",
        phone: "1234567890",
        email: "clinic@example.com"
      })
      |> Clinicpro.Clinics.create_clinic()

    clinic
  end
end
