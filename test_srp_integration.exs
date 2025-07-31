ExUnit.start()

# Include all the modules we created
code_paths = [
  "lib/clinicpro/accounts/doctor_handler.ex",
  "lib/clinicpro/accounts/doctor_service.ex",
  "lib/clinicpro/accounts/doctor_finder.ex",
  "lib/clinicpro/accounts/doctor_value.ex",
  "lib/clinicpro/accounts/patient_handler.ex",
  "lib/clinicpro/accounts/patient_service.ex",
  "lib/clinicpro/accounts/patient_finder.ex",
  "lib/clinicpro/accounts/patient_value.ex",
  "lib/clinicpro/accounts/admin_handler.ex",
  "lib/clinicpro/accounts/admin_service.ex",
  "lib/clinicpro/accounts/admin_finder.ex",
  "lib/clinicpro/accounts/admin_value.ex",
  "lib/clinicpro/auth/values/auth_token.ex"
]

Enum.each(code_paths, fn path ->
  if File.exists?(path) do
    Code.require_file(path)
  end
end)

defmodule SRPIntegrationTest do
  use ExUnit.Case, async: true

  alias Clinicpro.Accounts.{DoctorHandler, PatientHandler, AdminHandler}
  alias Clinicpro.Auth.Values.AuthToken

  describe "Doctor SRP flow" do
    test "initiate magic link" do
      assert {:ok, :email_sent} = DoctorHandler.initiate_magic_link("doctor@example.com")
    end

    test "handle login" do
      assert {:ok, doctor, session_data} = DoctorHandler.handle_magic_link_login("valid_token")
      assert doctor.id == 1
      assert session_data.doctor_id == 1
    end

    test "logout" do
      assert :ok = DoctorHandler.logout(1)
    end
  end

  describe "Patient SRP flow" do
    test "initiate magic link" do
      assert {:ok, :email_sent} = PatientHandler.initiate_magic_link("patient@example.com")
    end

    test "handle login" do
      assert {:ok, patient, session_data} = PatientHandler.handle_magic_link_login("valid_token")
      assert patient.id == 1
      assert session_data.patient_id == 1
    end

    test "register patient" do
      attrs = %{name: "John Doe", email: "john@example.com", phone: "1234567890"}
      assert {:ok, patient} = PatientHandler.register_patient(attrs)
      assert patient.name == "John Doe"
    end

    test "logout" do
      assert :ok = PatientHandler.logout(1)
    end
  end

  describe "Admin SRP flow" do
    test "initiate magic link" do
      assert {:ok, :email_sent} = AdminHandler.initiate_magic_link("admin@example.com")
    end

    test "handle login" do
      assert {:ok, admin, session_data} = AdminHandler.handle_magic_link_login("valid_token")
      assert admin.id == 1
      assert session_data.admin_id == 1
    end

    test "logout" do
      assert :ok = AdminHandler.logout(1)
    end
  end

  describe "AuthToken value object" do
    test "creates valid token" do
      expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)
      token = AuthToken.new("test_token", "test_context", "test@example.com", expires_at)

      assert token.token == "test_token"
      assert token.context == "test_context"
      assert token.sent_to == "test@example.com"
      refute AuthToken.expired?(token)
    end

    test "detects expired token" do
      expires_at = DateTime.utc_now() |> DateTime.add(-3600, :second)
      token = AuthToken.new("test_token", "test_context", "test@example.com", expires_at)

      assert AuthToken.expired?(token)
    end

    test "validates context" do
      assert AuthToken.valid_context?("patient_magic_link")
      assert AuthToken.valid_context?("doctor_magic_link")
      refute AuthToken.valid_context?("invalid_context")
    end
  end
end

ExUnit.run()
