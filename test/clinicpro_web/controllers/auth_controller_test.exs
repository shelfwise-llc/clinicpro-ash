defmodule ClinicproWeb.AuthControllerTest do
  use ClinicproWeb.ConnCase
  import Mox

  alias Clinicpro.Accounts
  alias Clinicpro.Accounts.AuthUser

  @valid_attrs %{
    email: "test@example.com",
    password: "Password123",
    role: "user"
  }

  setup %{conn: conn} do
    # Create a test clinic
    {:ok, clinic} = Clinicpro.Clinics.create_clinic(%{name: "Test Clinic"})

    # Create a valid user with the test clinic
    user_attrs = Map.put(@valid_attrs, :clinic_id, clinic.id)
    {:ok, user} = Accounts.register_auth_user(user_attrs)

    # Create an admin user
    admin_attrs = %{
      email: "admin@example.com",
      password: "Admin123",
      role: "admin",
      clinic_id: clinic.id
    }

    {:ok, admin} = Accounts.register_auth_user(admin_attrs)

    {:ok, conn: conn, user: user, admin: admin, clinic: clinic}
  end

  describe "new/2" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :new))
      assert html_response(conn, 200) =~ "Log in"
    end
  end

  describe "create/2" do
    test "logs in user and redirects when credentials are valid", %{
      conn: conn,
      user: user,
      clinic: clinic
    } do
      conn =
        post(conn, Routes.auth_path(conn, :create), %{
          "auth" => %{
            "email" => user.email,
            "password" => "Password123",
            "clinic_id" => clinic.id
          }
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Welcome back"
      assert Guardian.Plug.current_resource(conn).id == user.id
    end

    test "logs in admin without clinic_id and redirects to admin page", %{
      conn: conn,
      admin: admin
    } do
      conn =
        post(conn, Routes.auth_path(conn, :create), %{
          "auth" => %{"email" => admin.email, "password" => "Admin123"}
        })

      assert redirected_to(conn) == "/admin"
      assert get_flash(conn, :info) =~ "Welcome back, admin"
      assert Guardian.Plug.current_resource(conn).id == admin.id
    end

    test "renders errors when credentials are invalid", %{conn: conn, clinic: clinic} do
      conn =
        post(conn, Routes.auth_path(conn, :create), %{
          "auth" => %{
            "email" => "wrong@example.com",
            "password" => "wrongpass",
            "clinic_id" => clinic.id
          }
        })

      assert html_response(conn, 200) =~ "Invalid email/password combination"
      assert is_nil(Guardian.Plug.current_resource(conn))
    end

    test "renders errors when regular user doesn't provide clinic_id", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.auth_path(conn, :create), %{
          "auth" => %{"email" => user.email, "password" => "Password123"}
        })

      assert html_response(conn, 200) =~ "Please select a clinic"
      assert is_nil(Guardian.Plug.current_resource(conn))
    end
  end

  describe "delete/2" do
    test "logs out user and redirects to login page", %{conn: conn, user: user} do
      conn =
        conn
        |> Guardian.Plug.sign_in(user)
        |> get(Routes.auth_path(conn, :delete))

      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert get_flash(conn, :info) =~ "Logged out successfully"
      assert is_nil(Guardian.Plug.current_resource(conn))
    end
  end

  describe "forgot_password/2" do
    test "renders forgot password page", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :forgot_password))
      assert html_response(conn, 200) =~ "Forgot your password?"
    end
  end

  describe "send_reset_password_instructions/2" do
    test "redirects to login page with success message even if email not found", %{conn: conn} do
      conn =
        post(conn, Routes.auth_path(conn, :send_reset_password_instructions), %{
          "auth" => %{"email" => "nonexistent@example.com"}
        })

      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert get_flash(conn, :info) =~ "If your email is in our system"
    end

    test "sends reset instructions when email exists", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.auth_path(conn, :send_reset_password_instructions), %{
          "auth" => %{"email" => user.email}
        })

      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert get_flash(conn, :info) =~ "If your email is in our system"
      # In a real test, we would check that the email was actually sent
    end
  end

  describe "reset_password/2" do
    setup %{user: user} do
      {token, _user_token} = Accounts.AuthUserToken.build_email_token(user, "reset_password")
      %{token: token}
    end

    test "renders reset password page with valid token", %{conn: conn, token: token, user: user} do
      # Mock the get_auth_user_by_reset_password_token function
      expect(Accounts, :get_auth_user_by_reset_password_token, fn ^token -> user end)

      conn = get(conn, Routes.auth_path(conn, :reset_password, token))
      assert html_response(conn, 200) =~ "Reset password"
    end

    test "redirects to login page with error for invalid token", %{conn: conn} do
      # Mock the get_auth_user_by_reset_password_token function to return nil
      expect(Accounts, :get_auth_user_by_reset_password_token, fn _token -> nil end)

      conn = get(conn, Routes.auth_path(conn, :reset_password, "invalid_token"))
      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert get_flash(conn, :error) =~ "Reset password link is invalid"
    end
  end

  describe "update_password/2" do
    setup %{user: user} do
      {token, _user_token} = Accounts.AuthUserToken.build_email_token(user, "reset_password")
      %{token: token}
    end

    test "updates password and redirects with valid data", %{conn: conn, token: token, user: user} do
      # Mock the get_auth_user_by_reset_password_token function
      expect(Accounts, :get_auth_user_by_reset_password_token, fn ^token -> user end)

      # Mock the reset_auth_user_password function
      expect(Accounts, :reset_auth_user_password, fn ^user, %{"password" => "NewPassword123"} ->
        {:ok, user}
      end)

      conn =
        put(conn, Routes.auth_path(conn, :update_password, token), %{
          "auth_user" => %{"password" => "NewPassword123"}
        })

      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert get_flash(conn, :info) =~ "Password reset successfully"
    end

    test "renders errors with invalid data", %{conn: conn, token: token, user: user} do
      # Mock the get_auth_user_by_reset_password_token function
      expect(Accounts, :get_auth_user_by_reset_password_token, fn ^token -> user end)

      # Mock the reset_auth_user_password function to return error
      expect(Accounts, :reset_auth_user_password, fn ^user, %{"password" => "short"} ->
        {:error, %Ecto.Changeset{}}
      end)

      conn =
        put(conn, Routes.auth_path(conn, :update_password, token), %{
          "auth_user" => %{"password" => "short"}
        })

      assert html_response(conn, 200) =~ "Reset password"
    end

    test "redirects with error for invalid token", %{conn: conn} do
      # Mock the get_auth_user_by_reset_password_token function to return nil
      expect(Accounts, :get_auth_user_by_reset_password_token, fn _token -> nil end)

      conn =
        put(conn, Routes.auth_path(conn, :update_password, "invalid_token"), %{
          "auth_user" => %{"password" => "NewPassword123"}
        })

      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert get_flash(conn, :error) =~ "Reset password link is invalid"
    end
  end

  # Setup for mocking
  setup do
    Mox.stub_with(Accounts, Clinicpro.Accounts)
    :ok
  end
end
