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

  pipeline :patient_auth do
    plug ClinicproWeb.Plugs.EnsurePatientAuth
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
    get "/", AdminController, :dashboard
    get "/dashboard", AdminController, :dashboard

    # Admin edit routes with ID parameter
    get "/edit_doctor/:id", AdminController, :edit_doctor
    get "/edit_patient/:id", AdminController, :edit_patient
    get "/edit_appointment/:id", AdminController, :edit_appointment

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

    # Admin M-Pesa routes
    scope "/clinics/:clinic_id/mpesa", ClinicproWeb do
      # Removed duplicate pipe_through as it's already defined in the parent scope

      get "/", MPesaAdminController, :index
      get "/new", MPesaAdminController, :new_config
      post "/", MPesaAdminController, :create_config
      get "/:id/edit", MPesaAdminController, :edit_config
      put "/:id", MPesaAdminController, :update_config
      delete "/:id", MPesaAdminController, :delete
      get "/transactions", MPesaAdminController, :list_transactions
      get "/transactions/:id", MPesaAdminController, :transaction_details
      
      # Configuration details
      get "/configurations/:id", MPesaAdminController, :configuration_details
      post "/configurations/:id/activate", MPesaAdminController, :activate_config
      post "/configurations/:id/deactivate", MPesaAdminController, :deactivate_config
      
      # Callback logs
      get "/callbacks", MPesaAdminController, :callback_logs
      get "/callbacks/:id", MPesaAdminController, :callback_details

      # STK Push testing and URL registration
      get "/test-stk-push", MPesaAdminController, :test_stk_push_form
      post "/test-stk-push", MPesaAdminController, :test_stk_push
      post "/register-urls/:id", MPesaAdminController, :register_urls
    end

    # Keep ash_admin at the end for backward compatibility
    ash_admin("/ash")
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

    # Invoices management
    scope "/clinics/:clinic_id", ClinicproWeb do
      get "/invoices", InvoiceController, :index
      get "/invoices/new", InvoiceController, :new
      post "/invoices", InvoiceController, :create
      get "/invoices/:id", InvoiceController, :show
      get "/invoices/:id/edit", InvoiceController, :edit
      put "/invoices/:id", InvoiceController, :update
      delete "/invoices/:id", InvoiceController, :delete
    end
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
    get "/guest_booking/phone", GuestBookingController, :phone
    post "/guest_booking/phone", GuestBookingController, :phone_submit
    get "/guest_booking/invoice", GuestBookingController, :invoice
    post "/guest_booking/invoice", GuestBookingController, :invoice_submit
    get "/guest_booking/profile", GuestBookingController, :profile
    post "/guest_booking/profile", GuestBookingController, :profile_submit
    get "/guest_booking/complete", GuestBookingController, :complete
    # Keep the original paths as well for backward compatibility
    get "/booking/phone", GuestBookingController, :phone
    post "/booking/phone", GuestBookingController, :phone_submit
    get "/booking/invoice", GuestBookingController, :invoice
    post "/booking/invoice", GuestBookingController, :invoice_submit
    get "/booking/profile", GuestBookingController, :profile_submit
    get "/booking/complete", GuestBookingController, :complete

    # Public Patient Authentication Routes
    scope "/patient", ClinicproWeb do
      # Patient Authentication with OTP
      get "/request-otp", PatientAuthController, :request_otp
      post "/send-otp", PatientAuthController, :send_otp
      get "/verify-otp", PatientAuthController, :verify_otp_form
      post "/verify-otp", PatientAuthController, :verify_otp
      post "/logout", PatientAuthController, :logout
    end

    # Protected Patient Routes
    scope "/patient", ClinicproWeb do
      pipe_through [:patient_auth]

      # Patient Dashboard
      get "/dashboard", PatientAuthController, :dashboard

      # Patient Flow
      get "/receive-link/:token", PatientFlowController, :receive_link
      get "/welcome", PatientFlowController, :welcome
      get "/confirm-details", PatientFlowController, :confirm_details
      post "/confirm-details", PatientFlowController, :submit_confirmation
      get "/booking-confirmation", PatientFlowController, :booking_confirmation

      # Patient Medical Records
      get "/medical-records", PatientFlowController.MedicalRecords, :index
      get "/medical-records/:id", PatientFlowController.MedicalRecords, :show

      # Patient Appointment Booking
      get "/appointments", PatientFlowController.Appointments, :index
      get "/appointments/new", PatientFlowController.Appointments, :new
      post "/appointments/doctor", PatientFlowController.Appointments, :select_doctor_submit
      get "/appointments/date", PatientFlowController.Appointments, :select_date
      post "/appointments/date", PatientFlowController.Appointments, :select_date_submit
      get "/appointments/confirm", PatientFlowController.Appointments, :confirm
      post "/appointments/confirm", PatientFlowController.Appointments, :confirm_submit
      get "/appointments/:id", PatientFlowController.Appointments, :show
      post "/appointments/:id/cancel", PatientFlowController.Appointments, :cancel
    end

    # Doctor Flow
    get "/doctor/appointments", DoctorFlowController, :list_appointments
    get "/doctor/appointment/:id", DoctorFlowController, :access_appointment
    post "/doctor/appointment/:id", DoctorFlowController, :access_appointment_submit
    get "/doctor/medical-details/:id", DoctorFlowController, :fill_medical_details
    post "/doctor/medical-details/:id", DoctorFlowController, :fill_medical_details_submit
    # Add missing doctor flow routes
    get "/doctor/medical_details", DoctorFlowController, :fill_medical_details
    get "/doctor/diagnosis", DoctorFlowController, :diagnosis
    get "/doctor/save_profile/:id", DoctorFlowController, :save_to_profile
    get "/doctor/diagnosis/:id", DoctorFlowController, :record_diagnosis
    post "/doctor/diagnosis/:id", DoctorFlowController, :submit_diagnosis
    get "/doctor/prescriptions/:id", DoctorFlowController, :manage_prescriptions
    post "/doctor/prescriptions/:id", DoctorFlowController, :add_prescription
    post "/doctor/prescriptions/:id/complete", DoctorFlowController, :prescriptions_submit
    get "/doctor/save-profile/:id", DoctorFlowController, :save_to_profile
    post "/doctor/save-profile/:id", DoctorFlowController, :save_to_profile_submit
    get "/doctor/dashboard", DoctorFlowController, :dashboard

    # Search Flow
    get "/search", SearchController, :index
    post "/search", SearchController, :submit_query
    get "/search/filters", SearchController, :filters
    post "/search/filters", SearchController, :apply_filters
    get "/search/results", SearchController, :results
    get "/search/detail/:id", SearchController, :detail
  end

  # Patient-facing routes with versioning in path structure
  scope "/q", ClinicproWeb do
    pipe_through [:browser, :patient_auth]

    # Payment routes
    get "/payment/:invoice_id", PaymentController, :show
    post "/payment/mpesa/initiate", PaymentController, :initiate_mpesa
    get "/payment/mpesa/status/:transaction_id", PaymentController, :check_status

    # Appointment routes with type differentiation
    get "/appointment/:id", AppointmentController, :show
    get "/appointment/virtual/:id", AppointmentController, :virtual_link
    get "/appointment/onsite/:id", AppointmentController, :onsite_details
  end

  # M-Pesa callback routes with clinic-specific paths
  scope "/api/mpesa/callbacks", ClinicproWeb do
    pipe_through :api

    # STK Push callback route with clinic_id parameter
    post "/:clinic_id/stk", MPesaCallbackController, :stk_callback

    # C2B validation and confirmation routes with clinic_id parameter
    post "/:clinic_id/validation", MPesaCallbackController, :c2b_validation
    post "/:clinic_id/confirmation", MPesaCallbackController, :c2b_confirmation
  end

  # JSON:API routes
  scope "/api" do
    pipe_through :api

    forward "/json-api", AshJsonApi.Router,
      json_api_config: [
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
