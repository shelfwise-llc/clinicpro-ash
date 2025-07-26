# This file is loaded by test_helper.exs to bypass Ash resources and authentication in tests
# It sets up the environment to use mock modules instead of real Ash resources

# Enable test bypass mode
Application.put_env(:clinicpro, :test_bypass_enabled, true)

# Set token signing secret for tests
Application.put_env(
  :clinicpro,
  :token_signing_secret,
  "test_secret_key_for_ash_authentication_tokens"
)

# Define mock modules for tests
defmodule Clinicpro.TestBypass.MockUser do
  defstruct [:id, :email, :role, :doctor, :patient, :admin]
end

defmodule Clinicpro.TestBypass.MockDoctor do
  defstruct [:id, :first_name, :last_name, :specialty, :clinic_id]
end

defmodule Clinicpro.TestBypass.MockPatient do
  defstruct [:id, :first_name, :last_name, :date_of_birth]
end

defmodule Clinicpro.TestBypass.MockAppointment do
  defstruct [:id, :doctor_id, :patient_id, :date, :time, :type, :status, :patient, :doctor]
end

defmodule Clinicpro.TestBypass.MockAuth do
  @moduledoc """
  Mock authentication module for tests.
  """

  def sign_in(conn, user) do
    Plug.Conn.put_session(conn, :current_user, user)
  end

  def sign_out(conn) do
    Plug.Conn.delete_session(conn, :current_user)
  end

  def current_user(conn) do
    Plug.Conn.get_session(conn, :current_user)
  end

  def signed_in?(conn) do
    !!current_user(conn)
  end

  # Mock magic link authentication functions
  def generate_magic_link_token(email) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    Process.put({:magic_link_token, email}, token)
    token
  end

  def verify_magic_link_token(token) do
    # Find the email associated with this token
    email = Process.get({:magic_link_token, token})

    if email do
      {:ok,
       %Clinicpro.TestBypass.MockUser{id: Ecto.UUID.generate(), email: email, role: :patient}}
    else
      {:error, :invalid_token}
    end
  end
end

defmodule Clinicpro.TestBypass.MockAccountsAPI do
  @behaviour Clinicpro.AccountsAPIBehaviour

  @impl true
  def get_user(id) do
    {:ok,
     %Clinicpro.TestBypass.MockUser{
       id: id,
       email: "user-#{id}@example.com",
       role: :patient
     }}
  end

  @impl true
  def get_user_by_email(email) do
    {:ok,
     %Clinicpro.TestBypass.MockUser{
       id: "user-#{:erlang.phash2(email)}",
       email: email,
       role: :patient
     }}
  end

  @impl true
  def create_user(attrs) do
    {:ok,
     %Clinicpro.TestBypass.MockUser{
       id: Ecto.UUID.generate(),
       email: attrs[:email],
       role: attrs[:role] || :patient
     }}
  end

  @impl true
  def authenticate_by_magic_link(token) do
    Clinicpro.TestBypass.MockAuth.verify_magic_link_token(token)
  end

  @impl true
  def send_magic_link(email) do
    token = Clinicpro.TestBypass.MockAuth.generate_magic_link_token(email)
    {:ok, token}
  end
end

defmodule Clinicpro.TestBypass.MockAppointmentsAPI do
  @behaviour Clinicpro.AppointmentsAPIBehaviour

  @impl true
  def get_appointment(id) do
    {:ok,
     %Clinicpro.TestBypass.MockAppointment{
       id: id,
       doctor_id: "doctor-123",
       patient_id: "patient-456",
       date: "2025-07-25",
       time: "10:00 AM",
       type: "Consultation",
       status: "scheduled"
     }}
  end

  @impl true
  def list_appointments(filters) do
    doctor_id = filters[:doctor_id]
    patient_id = filters[:patient_id]

    appointments = [
      %Clinicpro.TestBypass.MockAppointment{
        id: "appt-1",
        doctor_id: doctor_id || "doctor-123",
        patient_id: patient_id || "patient-456",
        date: "2025-07-25",
        time: "10:00 AM",
        type: "Consultation",
        status: "scheduled"
      },
      %Clinicpro.TestBypass.MockAppointment{
        id: "appt-2",
        doctor_id: doctor_id || "doctor-123",
        patient_id: patient_id || "patient-789",
        date: "2025-07-26",
        time: "11:00 AM",
        type: "Follow-up",
        status: "scheduled"
      }
    ]

    {:ok, appointments}
  end

  @impl true
  def create_appointment(attrs) do
    {:ok,
     %Clinicpro.TestBypass.MockAppointment{
       id: Ecto.UUID.generate(),
       doctor_id: attrs[:doctor_id],
       patient_id: attrs[:patient_id],
       date: attrs[:date],
       time: attrs[:time],
       type: attrs[:type],
       status: "scheduled"
     }}
  end

  @impl true
  def update_appointment(id, attrs) do
    {:ok,
     %Clinicpro.TestBypass.MockAppointment{
       id: id,
       doctor_id: attrs[:doctor_id] || "doctor-123",
       patient_id: attrs[:patient_id] || "patient-456",
       date: attrs[:date] || "2025-07-25",
       time: attrs[:time] || "10:00 AM",
       type: attrs[:type] || "Consultation",
       status: attrs[:status] || "scheduled"
     }}
  end

  @impl true
  def delete_appointment(id) do
    {:ok, %Clinicpro.TestBypass.MockAppointment{id: id, status: "deleted"}}
  end
end

# Set up the application to use our mock modules
Application.put_env(:clinicpro, :accounts_api, Clinicpro.TestBypass.MockAccountsAPI)
Application.put_env(:clinicpro, :appointments_api, Clinicpro.TestBypass.MockAppointmentsAPI)
Application.put_env(:clinicpro, :auth_module, Clinicpro.TestBypass.MockAuth)

# Define a plug to bypass AshAuthentication in tests
defmodule Clinicpro.TestBypass.AuthPlug do
  @moduledoc """
  A plug that bypasses AshAuthentication in tests.

  This plug can be used in the router to replace the AshAuthentication plugs.
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    # Check if there's a current user in the session
    case Plug.Conn.get_session(conn, :current_user) do
      nil -> conn
      user -> Plug.Conn.assign(conn, :current_user, user)
    end
  end
end

# Helper module to set up the test environment
defmodule Clinicpro.TestBypass.Setup do
  @moduledoc """
  Helper module to set up the test environment.
  """

  def setup do
    # Make sure the test bypass is enabled
    Application.put_env(:clinicpro, :test_bypass_enabled, true)

    # Set up Mox expectations for the mock APIs
    Mox.stub(Clinicpro.MockAccountsAPI, :get_user, fn id ->
      Clinicpro.TestBypass.MockAccountsAPI.get_user(id)
    end)

    Mox.stub(Clinicpro.MockAccountsAPI, :get_user_by_email, fn email ->
      Clinicpro.TestBypass.MockAccountsAPI.get_user_by_email(email)
    end)

    Mox.stub(Clinicpro.MockAccountsAPI, :create_user, fn attrs ->
      Clinicpro.TestBypass.MockAccountsAPI.create_user(attrs)
    end)

    Mox.stub(Clinicpro.MockAccountsAPI, :authenticate_by_magic_link, fn token ->
      Clinicpro.TestBypass.MockAccountsAPI.authenticate_by_magic_link(token)
    end)

    Mox.stub(Clinicpro.MockAccountsAPI, :send_magic_link, fn email ->
      Clinicpro.TestBypass.MockAccountsAPI.send_magic_link(email)
    end)

    Mox.stub(Clinicpro.MockAppointmentsAPI, :get_appointment, fn id ->
      Clinicpro.TestBypass.MockAppointmentsAPI.get_appointment(id)
    end)

    Mox.stub(Clinicpro.MockAppointmentsAPI, :list_appointments, fn filters ->
      Clinicpro.TestBypass.MockAppointmentsAPI.list_appointments(filters)
    end)

    Mox.stub(Clinicpro.MockAppointmentsAPI, :create_appointment, fn attrs ->
      Clinicpro.TestBypass.MockAppointmentsAPI.create_appointment(attrs)
    end)

    Mox.stub(Clinicpro.MockAppointmentsAPI, :update_appointment, fn id, attrs ->
      Clinicpro.TestBypass.MockAppointmentsAPI.update_appointment(id, attrs)
    end)

    Mox.stub(Clinicpro.MockAppointmentsAPI, :delete_appointment, fn id ->
      Clinicpro.TestBypass.MockAppointmentsAPI.delete_appointment(id)
    end)

    :ok
  end
end
