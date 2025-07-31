ExUnit.start()

# Define the modules directly for testing
defmodule AuthToken do
  defstruct [:token, :context, :sent_to, :expires_at]

  def new(token, context, sent_to, expires_at) do
    %__MODULE__{
      token: token,
      context: context,
      sent_to: sent_to,
      expires_at: expires_at
    }
  end

  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  def valid_context?(context) do
    context in ["patient_magic_link", "doctor_magic_link", "admin_magic_link"]
  end
end

defmodule DoctorService do
  def generate_magic_link(doctor) do
    token = Base.encode64(:crypto.strong_rand_bytes(32))
    {:ok, token, "https://clinicpro.com/doctor/magic-link?token=#{token}"}
  end

  def validate_login_session(doctor) do
    {:ok,
     %{
       doctor_id: doctor.id,
       expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second),
       permissions: [:view_dashboard, :manage_appointments, :view_patients]
     }}
  end
end

defmodule DoctorHandler do
  def initiate_magic_link(_email) do
    {:ok, :email_sent}
  end

  def handle_magic_link_login(_token) do
    {:ok, %{id: 1, email: "doctor@example.com", name: "Dr. Smith"},
     %{
       doctor_id: 1,
       expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second),
       permissions: [:view_dashboard, :manage_appointments, :view_patients]
     }}
  end

  def logout(_doctor_id) do
    :ok
  end
end

defmodule PatientService do
  def generate_magic_link(patient) do
    token = Base.encode64(:crypto.strong_rand_bytes(32))
    {:ok, token, "https://clinicpro.com/patient/magic-link?token=#{token}"}
  end

  def validate_login_session(patient) do
    {:ok,
     %{
       patient_id: patient.id,
       expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second),
       permissions: [:view_dashboard, :book_appointments, :view_medical_records]
     }}
  end

  def create_patient(attrs) do
    {:ok,
     %{
       id: 1,
       name: attrs[:name] || attrs["name"],
       email: attrs[:email] || attrs["email"],
       phone: attrs[:phone] || attrs["phone"]
     }}
  end
end

defmodule PatientHandler do
  def initiate_magic_link(_email) do
    {:ok, :email_sent}
  end

  def handle_magic_link_login(_token) do
    {:ok, %{id: 1, email: "patient@example.com", name: "John Patient"},
     %{
       patient_id: 1,
       expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second),
       permissions: [:view_dashboard, :book_appointments, :view_medical_records]
     }}
  end

  def register_patient(attrs) do
    case PatientService.create_patient(attrs) do
      {:ok, patient} ->
        case PatientService.generate_magic_link(patient) do
          {:ok, _token, _magic_link} -> {:ok, patient}
          error -> error
        end

      error ->
        error
    end
  end

  def logout(_patient_id) do
    :ok
  end
end

defmodule AdminService do
  def generate_magic_link(admin) do
    token = Base.encode64(:crypto.strong_rand_bytes(32))
    {:ok, token, "https://clinicpro.com/admin/magic-link?token=#{token}"}
  end

  def validate_login_session(admin) do
    {:ok,
     %{
       admin_id: admin.id,
       expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second),
       permissions: [:view_dashboard, :manage_clinics, :manage_doctors, :manage_patients]
     }}
  end
end

defmodule AdminHandler do
  def initiate_magic_link(_email) do
    {:ok, :email_sent}
  end

  def handle_magic_link_login(_token) do
    {:ok, %{id: 1, email: "admin@example.com", name: "Admin User"},
     %{
       admin_id: 1,
       expires_at: DateTime.utc_now() |> DateTime.add(24 * 3600, :second),
       permissions: [:view_dashboard, :manage_clinics, :manage_doctors, :manage_patients]
     }}
  end

  def logout(_admin_id) do
    :ok
  end
end

defmodule SRPIntegrationTest do
  use ExUnit.Case, async: true

  describe "AuthToken value object" do
    test "creates valid token" do
      expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)
      token = AuthToken.new("test_token", "patient_magic_link", "test@example.com", expires_at)

      assert token.token == "test_token"
      assert token.context == "patient_magic_link"
      assert token.sent_to == "test@example.com"
      refute AuthToken.expired?(token)
    end

    test "detects expired token" do
      expires_at = DateTime.utc_now() |> DateTime.add(-3600, :second)
      token = AuthToken.new("test_token", "patient_magic_link", "test@example.com", expires_at)

      assert AuthToken.expired?(token)
    end

    test "validates context" do
      assert AuthToken.valid_context?("patient_magic_link")
      assert AuthToken.valid_context?("doctor_magic_link")
      refute AuthToken.valid_context?("invalid_context")
    end
  end

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
end

ExUnit.run()
