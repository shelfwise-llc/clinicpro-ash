defmodule ClinicproWeb.DoctorAuthController do
  use ClinicproWeb, :controller
  
  alias Clinicpro.Doctor
  alias Clinicpro.Auth.RateLimiter
  
  require Logger
  
  @doc """
  Display the doctor login page.
  """
  def login(conn, _params) do
    conn
    |> put_layout(html: :root)
    |> render("login.html")
  end

  @doc """
  Process doctor login.
  """
  def login_submit(conn, %{"email" => email, "password" => password}) do
    ip_address = get_client_ip(conn)
    
    # Check rate limiting first
    case RateLimiter.check_rate_limit(email, ip_address) do
      {:ok, remaining_attempts} ->
        attempt_login(conn, email, password, ip_address, remaining_attempts)
        
      {:error, :locked, remaining_seconds} ->
        minutes = div(remaining_seconds, 60)
        
        Logger.warn("Login attempt on locked account", 
          email: email, 
          ip_address: ip_address,
          remaining_lockout_minutes: minutes
        )
        
        conn
        |> put_flash(:error, "Account is locked due to too many failed attempts. Try again in #{minutes} minutes.")
        |> redirect(to: ~p"/doctor")
        
      {:error, :rate_limited, lockout_minutes} ->
        Logger.warn("Account locked due to rate limiting", 
          email: email, 
          ip_address: ip_address,
          lockout_minutes: lockout_minutes
        )
        
        conn
        |> put_flash(:error, "Too many failed login attempts. Account locked for #{lockout_minutes} minutes.")
        |> redirect(to: ~p"/doctor")
    end
  end

  @doc """
  Display the doctor dashboard.
  """
  def dashboard(conn, _params) do
    doctor_id = get_session(conn, :doctor_id)
    
    # For now, render a simple dashboard
    conn
    |> put_layout(html: :root)
    |> render("dashboard.html", doctor_id: doctor_id)
  end

  @doc """
  Process doctor logout.
  """
  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/")
  end
  
  # Helper functions
  defp attempt_login(conn, email, password, ip_address, remaining_attempts) do
    case Doctor.authenticate(email, password) do
      {:ok, doctor} ->
        # Successful login
        RateLimiter.record_successful_login(email, ip_address)
        
        Logger.info("Successful doctor login", 
          doctor_id: doctor.id,
          email: email,
          ip_address: ip_address,
          user_agent: get_user_agent(conn)
        )
        
        conn
        |> put_session(:doctor_id, doctor.id)
        |> put_session(:doctor_email, doctor.email)
        |> put_session(:login_time, DateTime.utc_now())
        |> put_session(:login_ip, ip_address)
        |> put_session(:user_agent, get_req_header(conn, "user-agent") |> List.first())
        |> put_flash(:info, "Welcome back, Dr. #{doctor.name}!")
        |> redirect(to: ~p"/doctor/dashboard")
        
      {:error, reason} ->
        # Failed login
        Logger.warn("Failed doctor login attempt", 
          email: email,
          ip_address: ip_address,
          reason: reason,
          remaining_attempts: remaining_attempts,
          user_agent: get_user_agent(conn)
        )
        
        error_message = case remaining_attempts do
          0 -> "Invalid credentials. Account will be locked after next failed attempt."
          1 -> "Invalid credentials. #{remaining_attempts} attempt remaining."
          n -> "Invalid credentials. #{n} attempts remaining."
        end
        
        conn
        |> put_flash(:error, error_message)
        |> redirect(to: ~p"/doctor")
    end
  end
  
  defp get_client_ip(conn) do
    # Handle various proxy headers
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> String.split(ip, ",") |> List.first() |> String.trim()
      [] -> 
        case get_req_header(conn, "x-real-ip") do
          [ip | _] -> ip
          [] -> to_string(:inet_parse.ntoa(conn.remote_ip))
        end
    end
  end
  
  defp get_user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [ua | _] -> ua
      [] -> "Unknown"
    end
  end
end
