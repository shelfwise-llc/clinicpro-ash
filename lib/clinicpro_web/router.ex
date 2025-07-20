defmodule ClinicproWeb.Router do
  use ClinicproWeb, :router
  use AshAuthentication.Phoenix.Router
  import AshAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ClinicproWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json-api"]
    plug AshJsonApi.Plug
    plug :load_from_bearer
  end

  # Authentication routes
  scope "/auth" do
    pipe_through :browser
    
    auth_routes_for Clinicpro.Accounts.User, to: ClinicproWeb.AuthController
    
    delete "/sign-out", ClinicproWeb.AuthController, :sign_out
  end

  # Admin routes
  scope "/admin" do
    pipe_through :browser
    
    ash_admin "/"
  end

  # Browser routes
  scope "/", ClinicproWeb do
    pipe_through :browser

    get "/", PageController, :home
    
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
    
    # Doctor Flow
    get "/doctor/appointments", DoctorFlowController, :list_appointments
    get "/doctor/appointment/:id", DoctorFlowController, :access_appointment
    get "/doctor/medical-details/:id", DoctorFlowController, :fill_medical_details
    post "/doctor/medical-details/:id", DoctorFlowController, :submit_medical_details
    get "/doctor/diagnosis/:id", DoctorFlowController, :record_diagnosis
    post "/doctor/diagnosis/:id", DoctorFlowController, :submit_diagnosis
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
