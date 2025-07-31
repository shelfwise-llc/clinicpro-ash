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
    plug :accepts, ["json-api", "json"]
    # Temporarily commenting out AshJsonApi.Plug until properly configured
    # plug AshJsonApi.Plug
    # plug :load_from_bearer
  end

  # Simple pipeline for health checks
  pipeline :health_check do
    plug :accepts, ["json"]
  end

  pipeline :patient_auth do
    plug ClinicproWeb.Plugs.EnsurePatientAuth
  end

  pipeline :doctor_auth do
    plug ClinicproWeb.Plugs.EnsureDoctorAuth
  end

  pipeline :admin_layout do
    plug :put_root_layout, {ClinicproWeb.Layouts, :admin}
  end

  pipeline :require_admin_login do
    plug ClinicproWeb.Plugs.EnsureAdminAuth
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
    get "/editappointment/:id", AdminController, :editappointment

    # Doctors management
    get "/doctors", AdminController, :doctors
    get "/_doctors/new", AdminController, :new_doctor
    post "/_doctors", AdminController, :create_doctor
    get "/_doctors/:id/edit", AdminController, :edit_doctor
    put "/_doctors/:id", AdminController, :update_doctor
    post "/_doctors/:id/delete", AdminController, :delete_doctor

    # Patients management
    get "/patients", AdminController, :patients
    get "/_patients/new", AdminController, :new_patient
    post "/_patients", AdminController, :create_patient
    get "/_patients/:id/edit", AdminController, :edit_patient
    put "/_patients/:id", AdminController, :update_patient
    post "/_patients/:id/delete", AdminController, :delete_patient

    # Appointments management
    get "/appointments", AdminController, :appointments
    get "/appointments/new", AdminController, :newappointment
    post "/appointments", AdminController, :createappointment
    get "/appointments/:id/edit", AdminController, :editappointment
    put "/appointments/:id", AdminController, :updateappointment
    post "/appointments/:id/delete", AdminController, :deleteappointment

    # Clinic settings
    get "/settings", AdminController, :settings
    post "/settings", AdminController, :update_settings

    # Admin M-Pesa routes - DISABLED (Using Paystack instead)
    # scope "/clinics/:clinic_id/mpesa", ClinicproWeb do
    #   # Removed duplicate pipe_through as it's already defined in the parent scope
    #
    #   get "/", MPesaAdminController, :index
    #   get "/new", MPesaAdminController, :new_config
    #   post "/", MPesaAdminController, :create_config
    #   get "/:id/edit", MPesaAdminController, :edit_config
    #   put "/:id", MPesaAdminController, :update_config
    #   delete "/:id", MPesaAdminController, :delete
    #   get "/transactions", MPesaAdminController, :list_transactions
    #   get "/transactions/:id", MPesaAdminController, :transaction_details
    #
    #   # Configuration details
    #   get "/configurations/:id", MPesaAdminController, :configuration_details
    #   post "/configurations/:id/activate", MPesaAdminController, :activate_config
    #   post "/configurations/:id/deactivate", MPesaAdminController, :deactivate_config
    #
    #   # Callback logs
    #   get "/callbacks", MPesaAdminController, :callback_logs
    #   get "/callbacks/:id", MPesaAdminController, :callback_details
    #
    #   # STK Push testing and URL registration
    #   get "/test-stk-push", MPesaAdminController, :test_stk_push_form
    #   post "/test-stk-push", MPesaAdminController, :test_stk_push
    #   post "/register-urls/:id", MPesaAdminController, :register_urls
    # end

    # Admin Paystack routes
    scope "/admin/clinics/:clinic_id/paystack", ClinicproWeb do
      pipe_through [:admin_layout, :require_admin_login]

      # Dashboard and main routes
      get "/", PaystackAdminController, :dashboard
      get "/new", PaystackAdminController, :new_config
      post "/", PaystackAdminController, :create_config
      get "/:id", PaystackAdminController, :show_config
      get "/:id/edit", PaystackAdminController, :edit_config
      put "/:id", PaystackAdminController, :update_config
      delete "/:id", PaystackAdminController, :delete_config
      get "/:id/deactivate", PaystackAdminController, :deactivate_config
      get "/:id/activate", PaystackAdminController, :activate_config
      post "/:id/activate", PaystackAdminController, :activate_config
      post "/:id/deactivate", PaystackAdminController, :deactivate_config

      # Configuration management
      get "/configs", PaystackAdminController, :list_configs
      get "/configs/new", PaystackAdminController, :new_config
      post "/configs", PaystackAdminController, :create_config
      get "/configs/:id", PaystackAdminController, :show_config
      get "/configs/:id/edit", PaystackAdminController, :edit_config
      put "/configs/:id", PaystackAdminController, :update_config
      delete "/configs/:id", PaystackAdminController, :delete_config

      # Configuration activation/deactivation
      post "/configs/:id/activate", PaystackAdminController, :activate_config
      post "/configs/:id/deactivate", PaystackAdminController, :deactivate_config

      # Subaccount management
      get "/subaccounts", PaystackAdminController, :list_subaccounts
      get "/subaccounts/new", PaystackAdminController, :new_subaccount
      post "/subaccounts", PaystackAdminController, :create_subaccount
      get "/subaccounts/:id", PaystackAdminController, :show_subaccount
      get "/subaccounts/:id/edit", PaystackAdminController, :edit_subaccount
      put "/subaccounts/:id", PaystackAdminController, :update_subaccount
      get "/subaccounts/:id/activate", PaystackAdminController, :activate_subaccount
      get "/subaccounts/:id/deactivate", PaystackAdminController, :deactivate_subaccount
      delete "/subaccounts/:id", PaystackAdminController, :delete_subaccount

      # Transaction management
      get "/transactions", PaystackAdminController, :list_transactions
      get "/transactions/:id", PaystackAdminController, :show_transaction
      post "/transactions/:id/verify", PaystackAdminController, :verify_transaction

      # Test payment
      get "/test-payment", PaystackAdminController, :test_payment_form
      post "/test-payment", PaystackAdminController, :process_test_payment

      # Webhook logs
      get "/webhooks", PaystackAdminController, :webhook_logs
      get "/webhooks/:id", PaystackAdminController, :webhook_details
      post "/webhooks/:id/retry", PaystackAdminController, :retry_webhook
    end

    # Keep ash_admin at the end for backward compatibility
    ash_admin("/ash")
  end

  # Doctor authentication routes (public)
  scope "/doctor", ClinicproWeb do
    pipe_through :browser

    # Doctor authentication
    get "/", DoctorAuthController, :login
    get "/login", DoctorAuthController, :login
    post "/login", DoctorAuthController, :login_submit
    get "/logout", DoctorAuthController, :logout
    post "/logout", DoctorAuthController, :logout
  end

  # Doctor protected routes (requires authentication)
  scope "/doctor", ClinicproWeb do
    pipe_through [:browser, :doctor_auth]

    # Dashboard
    get "/dashboard", DoctorController, :dashboard

    # Patient management
    get "/patients", DoctorController, :patients
    get "/patients/:id", DoctorController, :show_patient

    # Appointment management
    get "/appointments", DoctorController, :appointments
    get "/appointments/:id", DoctorController, :show_appointment
    put "/appointments/:id", DoctorController, :update_appointment
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
    get "/_doctors/new", AdminBypassController, :new_doctor
    post "/_doctors", AdminBypassController, :create_doctor
    get "/_doctors/:id/edit", AdminBypassController, :edit_doctor
    put "/_doctors/:id", AdminBypassController, :update_doctor
    delete "/_doctors/:id", AdminBypassController, :delete_doctor

    # Patients management
    get "/patients", AdminBypassController, :patients
    get "/_patients/new", AdminBypassController, :new_patient
    post "/_patients", AdminBypassController, :create_patient
    get "/_patients/:id/edit", AdminBypassController, :edit_patient
    put "/_patients/:id", AdminBypassController, :update_patient
    delete "/_patients/:id", AdminBypassController, :delete_patient

    # Appointments management
    get "/appointments", AdminBypassController, :appointments
    get "/appointments/new", AdminBypassController, :newappointment
    post "/appointments", AdminBypassController, :createappointment
    get "/appointments/:id/edit", AdminBypassController, :editappointment
    put "/appointments/:id", AdminBypassController, :updateappointment
    delete "/appointments/:id", AdminBypassController, :deleteappointment

    # Invoices management
    scope "/clinics/:clinic_id", ClinicproWeb do
      get "/invoices", InvoiceController, :index
      get "/invoices/new", InvoiceController, :new
      post "/invoices", InvoiceController, :create
      get "/invoices/:id", InvoiceController, :show
      get "/invoices/:id/edit", InvoiceController, :edit
      put "/invoices/:id", InvoiceController, :update
      delete "/invoices/:id", InvoiceController, :delete
      get "/invoices/:id/payment", InvoiceController, :payment
      post "/invoices/:id/process_payment", InvoiceController, :process_payment
    end
  end

  # Browser routes
  # Health check endpoint - accessible without authentication
  scope "/", ClinicproWeb do
    pipe_through :health_check

    get "/health", HealthController, :check
  end

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
    scope "/patient" do
      # Patient Authentication with OTP
      get "/request-otp", PatientAuthController, :request_otp
      post "/send-otp", PatientAuthController, :send_otp
      get "/verify-otp", PatientAuthController, :verify_otp_form
      post "/verify-otp", PatientAuthController, :verify_otp
      post "/logout", PatientAuthController, :logout
    end

    # Magic Link Authentication Routes
    live "/patient/magic-link", ClinicproWeb.Patient.AuthLive, :index
    live "/doctor/magic-link", ClinicproWeb.Doctor.AuthLive, :index
    live "/admin/magic-link", ClinicproWeb.Admin.AuthLive, :index
    live "/magic-link", MagicLinkLive, :index

    # Protected Patient Routes
    scope "/patient" do
      pipe_through [:patient_auth]

      # Patient Dashboard
      get "/dashboard", PatientAuthController, :dashboard

      # Patient Booking
      get "/book-appointment", PatientAuthController, :book_appointment
      post "/book-appointment", PatientAuthController, :create_appointment

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
    get "/doctor/appointment/:id", DoctorFlowController, :accessappointment
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

    # post "/payment/mpesa/initiate", PaymentController, :initiate_mpesa  # DISABLED - Using Paystack
    # get "/payment/mpesa/status/:transaction_id", PaymentController, :check_status  # DISABLED - Using Paystack

    # Appointment routes with type differentiation
    get "/appointment/:id", AppointmentController, :show
    get "/appointment/virtual/:id", AppointmentController, :virtual_link
    get "/appointment/onsite/:id", AppointmentController, :onsite_details
  end

  # M-Pesa callback routes with clinic-specific paths - DISABLED (Using Paystack instead)
  # scope "/api/mpesa/callbacks", ClinicproWeb do
  #   pipe_through :api
  #
  #   # STK Push callback route with clinic_id parameter
  #   post "/:clinic_id/stk", MPesaCallbackController, :stk_callback
  #
  #   # C2B validation and confirmation routes with clinic_id parameter
  #   post "/:clinic_id/validation", MPesaCallbackController, :c2b_validation
  #   post "/:clinic_id/confirmation", MPesaCallbackController, :c2b_confirmation
  # end

  # Paystack webhook route
  scope "/api/paystack", ClinicproWeb do
    pipe_through :api

    # Webhook callback route
    post "/webhook", PaystackWebhookController, :handle
  end

  # Health check route - accessible without authentication
  scope "/", ClinicproWeb do
    pipe_through :health_check

    get "/health", HealthController, :index
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
