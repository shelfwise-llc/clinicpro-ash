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
    get "/_doctors", AdminBypassController, :_doctors
    get "/_doctors/new", AdminBypassController, :new_doctor
    post "/_doctors", AdminBypassController, :create_doctor
    get "/_doctors/:id/edit", AdminBypassController, :edit_doctor
    put "/_doctors/:id", AdminBypassController, :update_doctor
    delete "/_doctors/:id", AdminBypassController, :delete_doctor
    
    # Patients management
    get "/_patients", AdminBypassController, :_patients
    get "/_patients/new", AdminBypassController, :new_patient
    post "/_patients", AdminBypassController, :create_patient
    get "/_patients/:id/edit", AdminBypassController, :edit_patient
    put "/_patients/:id", AdminBypassController, :update_patient
    delete "/_patients/:id", AdminBypassController, :delete_patient
    
    # Appointments management
    get "/appointments", AdminBypassController, :appointments
    get "/appointments/new", AdminBypassController, :new_appointment
    post "/appointments", AdminBypassController, :create_appointment
    get "/appointments/:id/edit", AdminBypassController, :edit_appointment
    put "/appointments/:id", AdminBypassController, :update_appointment
    delete "/appointments/:id", AdminBypassController, :delete_appointment
  end
end
