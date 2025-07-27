defmodule ClinicproWeb.Auth.EnsureClinicIsolationTest do
  use ClinicproWeb.ConnCase

  alias ClinicproWeb.Auth.EnsureClinicIsolation
  alias Clinicpro.Accounts.AuthUser
  alias Clinicpro.Auth.Guardian

  setup do
    # Create two different clinics
    {:ok, clinic1} =
      Clinicpro.Clinics.create_clinic(%{
        name: "Test Clinic 1",
        address: "123 Test St",
        phone: "1234567890",
        email: "clinic1@example.com"
      })

    {:ok, clinic2} =
      Clinicpro.Clinics.create_clinic(%{
        name: "Test Clinic 2",
        address: "456 Test Ave",
        phone: "0987654321",
        email: "clinic2@example.com"
      })

    # Create users for each clinic
    {:ok, user1} =
      Clinicpro.Accounts.register_user(%{
        email: "user1@example.com",
        password: "Password123",
        role: "user",
        clinic_id: clinic1.id
      })

    {:ok, user2} =
      Clinicpro.Accounts.register_user(%{
        email: "user2@example.com",
        password: "Password123",
        role: "user",
        clinic_id: clinic2.id
      })

    {:ok, admin} =
      Clinicpro.Accounts.register_user(%{
        email: "admin@example.com",
        password: "Password123",
        role: "admin",
        clinic_id: clinic1.id
      })

    {:ok,
     %{
       clinic1: clinic1,
       clinic2: clinic2,
       user1: user1,
       user2: user2,
       admin: admin
     }}
  end

  describe "init/1" do
    test "returns options unchanged" do
      opts = [some: :option]
      assert EnsureClinicIsolation.init(opts) == opts
    end
  end

  describe "call/2" do
    test "allows access when user's clinic_id matches param clinic_id", %{conn: conn} do
      clinic_id = Ecto.UUID.generate()
      user = %AuthUser{id: Ecto.UUID.generate(), clinic_id: clinic_id, role: "user"}

      conn =
        conn
        |> assign(:current_user, user)
        |> Guardian.Plug.put_current_resource(user)
        |> Phoenix.Controller.fetch_query_params()
        |> Map.put(:params, %{"clinic_id" => clinic_id})
        |> EnsureClinicIsolation.call([])

      refute conn.halted
    end

    test "allows access for admin users regardless of clinic_id", %{conn: conn} do
      user_clinic_id = Ecto.UUID.generate()
      param_clinic_id = Ecto.UUID.generate()
      user = %AuthUser{id: Ecto.UUID.generate(), clinic_id: user_clinic_id, role: "admin"}

      conn =
        conn
        |> assign(:current_user, user)
        |> Guardian.Plug.put_current_resource(user)
        |> Phoenix.Controller.fetch_query_params()
        |> Map.put(:params, %{"clinic_id" => param_clinic_id})
        |> EnsureClinicIsolation.call([])

      refute conn.halted
    end

    test "allows access when no clinic_id in params", %{conn: conn} do
      clinic_id = Ecto.UUID.generate()
      user = %AuthUser{id: Ecto.UUID.generate(), clinic_id: clinic_id, role: "user"}

      conn =
        conn
        |> assign(:current_user, user)
        |> Guardian.Plug.put_current_resource(user)
        |> Phoenix.Controller.fetch_query_params()
        |> Map.put(:params, %{})
        |> EnsureClinicIsolation.call([])

      refute conn.halted
    end

    test "denies access when user's clinic_id doesn't match param clinic_id", %{conn: conn} do
      user_clinic_id = Ecto.UUID.generate()
      param_clinic_id = Ecto.UUID.generate()
      user = %AuthUser{id: Ecto.UUID.generate(), clinic_id: user_clinic_id, role: "user"}

      conn =
        conn
        |> assign(:current_user, user)
        |> Guardian.Plug.put_current_resource(user)
        |> Phoenix.Controller.fetch_query_params()
        |> Map.put(:params, %{"clinic_id" => param_clinic_id})
        |> EnsureClinicIsolation.call([])

      assert conn.halted
      assert conn.status == 403
    end

    test "allows access when no user is authenticated", %{conn: conn} do
      conn =
        conn
        |> Phoenix.Controller.fetch_query_params()
        |> Map.put(:params, %{"clinic_id" => Ecto.UUID.generate()})
        |> EnsureClinicIsolation.call([])

      refute conn.halted
    end
  end
end
