defmodule ClinicproWeb.Router do
  use ClinicproWeb, :router
  # Temporarily disabled AshAuthentication
  # use AshAuthentication.Phoenix.Router
  import AshAdmin.Router
  import ClinicproWeb.RouterBypass

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ClinicproWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # Temporarily disabled AshAuthentication plugs
    # plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json-api"]
    plug AshJsonApi.Plug
    # plug :load_from_bearer
  end

  # Authentication routes - temporarily disabled
  # scope "/auth" do
  #   pipe_through :browser
  #   
  #   auth_routes_for Clinicpro.Accounts.User, to: ClinicproWeb.AuthController
  #   
  #   delete "/sign-out", ClinicproWeb.AuthController, :sign_out
  # end

  # Admin routes
  scope "/admin", ClinicproWeb do
    pipe_through :browser
    
    # Admin authentication
    get "/login", AdminController, :login
    post "/login", AdminController, :login_submit
    post "/logout", AdminController, :logout
    
    # Admin dashboard
    get "/dashboard", AdminController, :dashboard
    
    # Doctors management
    get "/doctors", AdminController, :doctors
    get "/doctors/new", AdminController, :new_doctor
    post "/doctors", AdminController, :create_doctor
    get "/doctors/:id/edit", AdminController, :edit_doctor
    put "/doctors/:id", AdminController, :update_doctor
    post "/doctors/:id/delete", AdminController, :delete_doctor
    
    # Patients management
    get "/patients", AdminController, :patients
    get "/patients/new", AdminController, :new_patient
    post "/patients", AdminController, :create_patient
    get "/patients/:id/edit", AdminController, :edit_patient
    put "/patients/:id", AdminController, :update_patient
    post "/patients/:id/delete", AdminController, :delete_patient
    
    # Appointments management
    get "/appointments", AdminController, :appointments
    get "/appointments/new", AdminController, :new_appointment
    post "/appointments", AdminController, :create_appointment
    get "/appointments/:id/edit", AdminController, :edit_appointment
    put "/appointments/:id", AdminController, :update_appointment
    post "/appointments/:id/delete", AdminController, :delete_appointment
    
    # Clinic settings
    get "/settings", AdminController, :settings
    post "/settings", AdminController, :update_settings
    
    # Keep ash_admin at the end for backward compatibility
    ash_admin "/ash"
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

  # Browser routes
  scope "/", ClinicproWeb do
    pipe_through :browser

    get "/", PageController, :home
    
    # Doctor Flow Bypass Routes
    doctor_flow_bypass_routes()
    
    # Guest Booking Flow
    get "/booking", GuestBookingController, :index
    get "/booking/type", GuestBookingController, :type
    post "/booking/type", GuestBookingController, :type_submit
    get "/booking/phone", GuestBookingController, :phone
    post "/booking/phone", GuestBookingController, :phone_submit
    get "/booking/invoice", GuestBookingController, :invoice
    post "/booking/invoice", GuestBookingController, :invoice_submit
    get "/booking/profile", GuestBookingController, :profile
    post "/booking/profile", GuestBookingController, :profile_submit
    get "/booking/complete", GuestBookingController, :complete
    
    # Patient Flow
    get "/patient/receive-link/:token", PatientFlowController, :receive_link
    get "/patient/welcome", PatientFlowController, :welcome
    get "/patient/confirm-details", PatientFlowController, :confirm_details
    post "/patient/confirm-details", PatientFlowController, :submit_confirmation
    get "/patient/booking-confirmation", PatientFlowController, :booking_confirmation
    
    # Patient Medical Records
    get "/patient/medical-records", PatientFlowController.MedicalRecords, :index
    get "/patient/medical-records/:id", PatientFlowController.MedicalRecords, :show
    
    # Patient Appointment Booking
    get "/patient/appointments", PatientFlowController.Appointments, :index
    get "/patient/appointments/new", PatientFlowController.Appointments, :new
    post "/patient/appointments/doctor", PatientFlowController.Appointments, :select_doctor_submit
    get "/patient/appointments/date", PatientFlowController.Appointments, :select_date
    post "/patient/appointments/date", PatientFlowController.Appointments, :select_date_submit
    get "/patient/appointments/confirm", PatientFlowController.Appointments, :confirm
    post "/patient/appointments/confirm", PatientFlowController.Appointments, :confirm_submit
    get "/patient/appointments/:id", PatientFlowController.Appointments, :show
    post "/patient/appointments/:id/cancel", PatientFlowController.Appointments, :cancel
    
    # Doctor Flow
    get "/doctor/appointments", DoctorFlowController, :list_appointments
    get "/doctor/appointment/:id", DoctorFlowController, :access_appointment
    get "/doctor/medical-details/:id", DoctorFlowController, :fill_medical_details
    post "/doctor/medical-details/:id", DoctorFlowController, :submit_medical_details
    get "/doctor/diagnosis/:id", DoctorFlowController, :record_diagnosis
    post "/doctor/diagnosis/:id", DoctorFlowController, :submit_diagnosis
    get "/doctor/prescriptions/:id", DoctorFlowController, :manage_prescriptions
    post "/doctor/prescriptions/:id", DoctorFlowController, :add_prescription
    post "/doctor/prescriptions/:id/complete", DoctorFlowController, :prescriptions_submit
    get "/doctor/save-profile/:id", DoctorFlowController, :save_to_profile
    post "/doctor/save-profile/:id", DoctorFlowController, :submit_profile_save
    
    # Search Flow
    get "/search", SearchController, :index
    post "/search", SearchController, :submit_query
    get "/search/filters", SearchController, :filters
    post "/search/filters", SearchController, :apply_filters
    get "/search/results", SearchController, :results
    get "/search/detail/:id", SearchController, :detail
  end

  # JSON:API routes
  scope "/api" do
    pipe_through :api
    
    forward "/json-api", AshJsonApi.Router, json_api_config: [
      apis: [Clinicpro.Accounts, Clinicpro.Clinics]
    ]
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:clinicpro, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ClinicproWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
