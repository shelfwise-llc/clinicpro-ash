defmodule ClinicproWeb.RouterAdminBypass do
  use ClinicproWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ClinicproWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Admin Bypass Routes (Direct Ecto operations)
  scope "/admin_bypass", ClinicproWeb do
    pipe_through :browser
    
    # Admin dashboard
    get "/", AdminBypassController, :index
    
    # Database seeding
    post "/seed", AdminBypassController, :seed_database
    
    # Doctors management
    get "/doctors", AdminBypassController, :doctors
    get "/doctors/new", AdminBypassController, :new_doctor
    post "/doctors", AdminBypassController, :create_doctor
    get "/doctors/:id/edit", AdminBypassController, :edit_doctor
    put "/doctors/:id", AdminBypassController, :update_doctor
    delete "/doctors/:id", AdminBypassController, :delete_doctor
    
    # Patients management
    get "/patients", AdminBypassController, :patients
    get "/patients/new", AdminBypassController, :new_patient
    post "/patients", AdminBypassController, :create_patient
    get "/patients/:id/edit", AdminBypassController, :edit_patient
    put "/patients/:id", AdminBypassController, :update_patient
    delete "/patients/:id", AdminBypassController, :delete_patient
    
    # Appointments management
    get "/appointments", AdminBypassController, :appointments
    get "/appointments/new", AdminBypassController, :new_appointment
    post "/appointments", AdminBypassController, :create_appointment
    get "/appointments/:id/edit", AdminBypassController, :edit_appointment
    put "/appointments/:id", AdminBypassController, :update_appointment
    delete "/appointments/:id", AdminBypassController, :delete_appointment
  end
end
