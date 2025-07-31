ExUnit.start()

defmodule Clinicpro.Accounts.DoctorHandlerTest do
  use ExUnit.Case, async: true

  alias Clinicpro.Accounts.DoctorHandler

  describe "initiate_magic_link/1" do
    test "returns email_sent for existing doctor" do
      assert {:ok, :email_sent} = DoctorHandler.initiate_magic_link("doctor@example.com")
    end

    test "returns email_sent for non-existing doctor" do
      assert {:ok, :email_sent} = DoctorHandler.initiate_magic_link("nonexistent@example.com")
    end
  end

  describe "handle_magic_link_login/1" do
    test "returns doctor for valid token" do
      assert {:ok, doctor, _session_data} = DoctorHandler.handle_magic_link_login("valid_token")
      assert doctor.id == 1
      assert doctor.email == "doctor@example.com"
    end
  end

  describe "logout/1" do
    test "invalidates session" do
      assert :ok = DoctorHandler.logout(1)
    end
  end
end

defmodule Clinicpro.Accounts.PatientHandlerTest do
  use ExUnit.Case, async: true

  alias Clinicpro.Accounts.PatientHandler

  describe "initiate_magic_link/1" do
    test "returns email_sent for existing patient" do
      assert {:ok, :email_sent} = PatientHandler.initiate_magic_link("patient@example.com")
    end

    test "returns email_sent for non-existing patient" do
      assert {:ok, :email_sent} = PatientHandler.initiate_magic_link("nonexistent@example.com")
    end
  end

  describe "handle_magic_link_login/1" do
    test "returns patient for valid token" do
      assert {:ok, patient, _session_data} = PatientHandler.handle_magic_link_login("valid_token")
      assert patient.id == 1
      assert patient.email == "patient@example.com"
    end
  end

  describe "register_patient/1" do
    test "registers new patient" do
      attrs = %{name: "John Doe", email: "john@example.com", phone: "1234567890"}
      assert {:ok, patient} = PatientHandler.register_patient(attrs)
      assert patient.name == "John Doe"
      assert patient.email == "john@example.com"
    end
  end

  describe "logout/1" do
    test "invalidates session" do
      assert :ok = PatientHandler.logout(1)
    end
  end
end

defmodule Clinicpro.Accounts.AdminHandlerTest do
  use ExUnit.Case, async: true

  alias Clinicpro.Accounts.AdminHandler

  describe "initiate_magic_link/1" do
    test "returns email_sent for existing admin" do
      assert {:ok, :email_sent} = AdminHandler.initiate_magic_link("admin@example.com")
    end

    test "returns email_sent for non-existing admin" do
      assert {:ok, :email_sent} = AdminHandler.initiate_magic_link("nonexistent@example.com")
    end
  end

  describe "handle_magic_link_login/1" do
    test "returns admin for valid token" do
      assert {:ok, admin, _session_data} = AdminHandler.handle_magic_link_login("valid_token")
      assert admin.id == 1
      assert admin.email == "admin@example.com"
    end
  end

  describe "logout/1" do
    test "invalidates session" do
      assert :ok = AdminHandler.logout(1)
    end
  end
end

ExUnit.start()
ExUnit.run()
