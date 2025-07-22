--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_bypass_appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_bypass_appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doctor_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    status text DEFAULT 'scheduled'::text,
    reason text,
    notes text,
    diagnosis text,
    prescription text,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: admin_bypass_doctors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_bypass_doctors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    email text NOT NULL,
    phone text,
    specialty text,
    bio text,
    active boolean DEFAULT true,
    years_of_experience integer,
    consultation_fee numeric,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: admin_bypass_invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_bypass_invoices (
    id bigint NOT NULL,
    invoice_number character varying(255) NOT NULL,
    amount numeric(10,2) NOT NULL,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    due_date date NOT NULL,
    description character varying(255),
    payment_reference character varying(255),
    notes text,
    items jsonb DEFAULT '[]'::jsonb,
    patient_id uuid NOT NULL,
    clinic_id uuid NOT NULL,
    appointment_id uuid,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admin_bypass_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_bypass_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_bypass_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_bypass_invoices_id_seq OWNED BY public.admin_bypass_invoices.id;


--
-- Name: admin_bypass_patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_bypass_patients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    email text NOT NULL,
    phone text,
    date_of_birth date,
    gender text,
    medical_history text,
    active boolean DEFAULT true,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    id bigint NOT NULL,
    email character varying(255),
    name character varying(255),
    password_hash character varying(255),
    role character varying(255),
    active boolean DEFAULT false NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointments (
    id bigint NOT NULL,
    date date,
    start_time time(0) without time zone,
    end_time time(0) without time zone,
    status character varying(255),
    type character varying(255),
    notes text,
    doctor_id bigint,
    patient_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointments_id_seq OWNED BY public.appointments.id;


--
-- Name: clinic_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clinic_settings (
    id bigint NOT NULL,
    key character varying(255),
    value text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: clinic_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clinic_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clinic_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clinic_settings_id_seq OWNED BY public.clinic_settings.id;


--
-- Name: doctors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.doctors (
    id bigint NOT NULL,
    name character varying(255),
    specialty character varying(255),
    email character varying(255),
    phone character varying(255),
    status character varying(255),
    active boolean DEFAULT false NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: doctors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.doctors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doctors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.doctors_id_seq OWNED BY public.doctors.id;


--
-- Name: mpesa_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mpesa_configs (
    id bigint NOT NULL,
    clinic_id uuid NOT NULL,
    consumer_key character varying(255) NOT NULL,
    consumer_secret character varying(255) NOT NULL,
    passkey character varying(255) NOT NULL,
    shortcode character varying(255) NOT NULL,
    c2b_shortcode character varying(255),
    environment character varying(255) DEFAULT 'sandbox'::character varying,
    stk_callback_url character varying(255),
    c2b_validation_url character varying(255),
    c2b_confirmation_url character varying(255),
    active boolean DEFAULT true,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: mpesa_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mpesa_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mpesa_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mpesa_configs_id_seq OWNED BY public.mpesa_configs.id;


--
-- Name: mpesa_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mpesa_transactions (
    id bigint NOT NULL,
    clinic_id uuid,
    checkout_request_id character varying(255),
    merchant_request_id character varying(255),
    reference character varying(255) NOT NULL,
    phone character varying(255) NOT NULL,
    amount numeric NOT NULL,
    description character varying(255),
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    result_code character varying(255),
    result_desc character varying(255),
    transaction_date timestamp(0) without time zone,
    mpesa_receipt_number character varying(255),
    type character varying(255) NOT NULL,
    raw_request jsonb,
    raw_response jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: mpesa_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mpesa_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mpesa_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mpesa_transactions_id_seq OWNED BY public.mpesa_transactions.id;


--
-- Name: otp_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_configs (
    id uuid NOT NULL,
    clinic_identifier character varying(255) NOT NULL,
    sms_provider character varying(255),
    sms_api_key character varying(255),
    sms_sender_id character varying(255),
    sms_enabled boolean DEFAULT true,
    email_provider character varying(255),
    email_api_key character varying(255),
    email_from_address character varying(255),
    email_enabled boolean DEFAULT true,
    preferred_method character varying(255) DEFAULT 'sms'::character varying,
    otp_expiry_minutes integer DEFAULT 5,
    max_attempts_per_hour integer DEFAULT 5,
    lockout_minutes integer DEFAULT 30,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: otp_secrets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_secrets (
    id uuid NOT NULL,
    secret character varying(255) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    expires_at timestamp(0) without time zone,
    patient_id bigint NOT NULL,
    clinic_identifier character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patients (
    id bigint NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    phone character varying(255),
    date_of_birth date,
    gender character varying(255),
    address text,
    medical_history text,
    insurance_provider character varying(255),
    insurance_number character varying(255),
    status character varying(255),
    active boolean DEFAULT false NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: patients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patients_id_seq OWNED BY public.patients.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: admin_bypass_invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_invoices ALTER COLUMN id SET DEFAULT nextval('public.admin_bypass_invoices_id_seq'::regclass);


--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: appointments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments ALTER COLUMN id SET DEFAULT nextval('public.appointments_id_seq'::regclass);


--
-- Name: clinic_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_settings ALTER COLUMN id SET DEFAULT nextval('public.clinic_settings_id_seq'::regclass);


--
-- Name: doctors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doctors ALTER COLUMN id SET DEFAULT nextval('public.doctors_id_seq'::regclass);


--
-- Name: mpesa_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mpesa_configs ALTER COLUMN id SET DEFAULT nextval('public.mpesa_configs_id_seq'::regclass);


--
-- Name: mpesa_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mpesa_transactions ALTER COLUMN id SET DEFAULT nextval('public.mpesa_transactions_id_seq'::regclass);


--
-- Name: patients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients ALTER COLUMN id SET DEFAULT nextval('public.patients_id_seq'::regclass);


--
-- Name: admin_bypass_appointments admin_bypass_appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_appointments
    ADD CONSTRAINT admin_bypass_appointments_pkey PRIMARY KEY (id);


--
-- Name: admin_bypass_doctors admin_bypass_doctors_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_doctors
    ADD CONSTRAINT admin_bypass_doctors_email_key UNIQUE (email);


--
-- Name: admin_bypass_doctors admin_bypass_doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_doctors
    ADD CONSTRAINT admin_bypass_doctors_pkey PRIMARY KEY (id);


--
-- Name: admin_bypass_invoices admin_bypass_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_invoices
    ADD CONSTRAINT admin_bypass_invoices_pkey PRIMARY KEY (id);


--
-- Name: admin_bypass_patients admin_bypass_patients_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_patients
    ADD CONSTRAINT admin_bypass_patients_email_key UNIQUE (email);


--
-- Name: admin_bypass_patients admin_bypass_patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_patients
    ADD CONSTRAINT admin_bypass_patients_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: clinic_settings clinic_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_settings
    ADD CONSTRAINT clinic_settings_pkey PRIMARY KEY (id);


--
-- Name: doctors doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (id);


--
-- Name: mpesa_configs mpesa_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mpesa_configs
    ADD CONSTRAINT mpesa_configs_pkey PRIMARY KEY (id);


--
-- Name: mpesa_transactions mpesa_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_pkey PRIMARY KEY (id);


--
-- Name: otp_configs otp_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_configs
    ADD CONSTRAINT otp_configs_pkey PRIMARY KEY (id);


--
-- Name: otp_secrets otp_secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_secrets
    ADD CONSTRAINT otp_secrets_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: admin_bypass_appointments_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_appointments_date_idx ON public.admin_bypass_appointments USING btree (date);


--
-- Name: admin_bypass_appointments_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_appointments_date_index ON public.admin_bypass_appointments USING btree (date);


--
-- Name: admin_bypass_appointments_doctor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_appointments_doctor_id_idx ON public.admin_bypass_appointments USING btree (doctor_id);


--
-- Name: admin_bypass_appointments_doctor_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_appointments_doctor_id_index ON public.admin_bypass_appointments USING btree (doctor_id);


--
-- Name: admin_bypass_appointments_patient_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_appointments_patient_id_idx ON public.admin_bypass_appointments USING btree (patient_id);


--
-- Name: admin_bypass_appointments_patient_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_appointments_patient_id_index ON public.admin_bypass_appointments USING btree (patient_id);


--
-- Name: admin_bypass_appointments_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_appointments_status_index ON public.admin_bypass_appointments USING btree (status);


--
-- Name: admin_bypass_doctors_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admin_bypass_doctors_email_index ON public.admin_bypass_doctors USING btree (email);


--
-- Name: admin_bypass_doctors_last_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_doctors_last_name_idx ON public.admin_bypass_doctors USING btree (last_name);


--
-- Name: admin_bypass_invoices_appointment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_invoices_appointment_id_index ON public.admin_bypass_invoices USING btree (appointment_id);


--
-- Name: admin_bypass_invoices_clinic_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_invoices_clinic_id_index ON public.admin_bypass_invoices USING btree (clinic_id);


--
-- Name: admin_bypass_invoices_invoice_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admin_bypass_invoices_invoice_number_index ON public.admin_bypass_invoices USING btree (invoice_number);


--
-- Name: admin_bypass_invoices_patient_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_invoices_patient_id_index ON public.admin_bypass_invoices USING btree (patient_id);


--
-- Name: admin_bypass_invoices_payment_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_invoices_payment_reference_index ON public.admin_bypass_invoices USING btree (payment_reference);


--
-- Name: admin_bypass_invoices_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_invoices_status_index ON public.admin_bypass_invoices USING btree (status);


--
-- Name: admin_bypass_patients_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admin_bypass_patients_email_index ON public.admin_bypass_patients USING btree (email);


--
-- Name: admin_bypass_patients_last_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_bypass_patients_last_name_idx ON public.admin_bypass_patients USING btree (last_name);


--
-- Name: admins_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins_email_index ON public.admins USING btree (email);


--
-- Name: appointments_doctor_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_doctor_id_index ON public.appointments USING btree (doctor_id);


--
-- Name: appointments_patient_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_patient_id_index ON public.appointments USING btree (patient_id);


--
-- Name: clinic_settings_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX clinic_settings_key_index ON public.clinic_settings USING btree (key);


--
-- Name: doctors_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX doctors_email_index ON public.doctors USING btree (email);


--
-- Name: mpesa_configs_clinic_id_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mpesa_configs_clinic_id_active_index ON public.mpesa_configs USING btree (clinic_id, active) WHERE (active = true);


--
-- Name: mpesa_configs_clinic_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mpesa_configs_clinic_id_index ON public.mpesa_configs USING btree (clinic_id);


--
-- Name: mpesa_transactions_checkout_request_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mpesa_transactions_checkout_request_id_index ON public.mpesa_transactions USING btree (checkout_request_id);


--
-- Name: mpesa_transactions_clinic_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mpesa_transactions_clinic_id_index ON public.mpesa_transactions USING btree (clinic_id);


--
-- Name: mpesa_transactions_mpesa_receipt_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mpesa_transactions_mpesa_receipt_number_index ON public.mpesa_transactions USING btree (mpesa_receipt_number);


--
-- Name: mpesa_transactions_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mpesa_transactions_reference_index ON public.mpesa_transactions USING btree (reference);


--
-- Name: mpesa_transactions_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mpesa_transactions_status_index ON public.mpesa_transactions USING btree (status);


--
-- Name: otp_configs_clinic_identifier_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX otp_configs_clinic_identifier_index ON public.otp_configs USING btree (clinic_identifier);


--
-- Name: otp_secrets_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX otp_secrets_active_index ON public.otp_secrets USING btree (active);


--
-- Name: otp_secrets_clinic_identifier_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX otp_secrets_clinic_identifier_index ON public.otp_secrets USING btree (clinic_identifier);


--
-- Name: otp_secrets_patient_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX otp_secrets_patient_id_index ON public.otp_secrets USING btree (patient_id);


--
-- Name: patients_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patients_email_index ON public.patients USING btree (email);


--
-- Name: admin_bypass_appointments admin_bypass_appointments_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_appointments
    ADD CONSTRAINT admin_bypass_appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.admin_bypass_doctors(id) ON DELETE CASCADE;


--
-- Name: admin_bypass_appointments admin_bypass_appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_appointments
    ADD CONSTRAINT admin_bypass_appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.admin_bypass_patients(id) ON DELETE CASCADE;


--
-- Name: admin_bypass_invoices admin_bypass_invoices_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_invoices
    ADD CONSTRAINT admin_bypass_invoices_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.admin_bypass_appointments(id) ON DELETE SET NULL;


--
-- Name: admin_bypass_invoices admin_bypass_invoices_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_invoices
    ADD CONSTRAINT admin_bypass_invoices_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.admin_bypass_doctors(id) ON DELETE RESTRICT;


--
-- Name: admin_bypass_invoices admin_bypass_invoices_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_bypass_invoices
    ADD CONSTRAINT admin_bypass_invoices_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.admin_bypass_patients(id) ON DELETE RESTRICT;


--
-- Name: appointments appointments_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id);


--
-- Name: appointments appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: mpesa_configs mpesa_configs_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mpesa_configs
    ADD CONSTRAINT mpesa_configs_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.admin_bypass_doctors(id) ON DELETE CASCADE;


--
-- Name: mpesa_transactions mpesa_transactions_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.admin_bypass_doctors(id) ON DELETE SET NULL;


--
-- Name: otp_secrets otp_secrets_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_secrets
    ADD CONSTRAINT otp_secrets_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20250720184820);
INSERT INTO public."schema_migrations" (version) VALUES (20250720185102);
INSERT INTO public."schema_migrations" (version) VALUES (20250720185109);
INSERT INTO public."schema_migrations" (version) VALUES (20250720185119);
INSERT INTO public."schema_migrations" (version) VALUES (20250720185124);
INSERT INTO public."schema_migrations" (version) VALUES (20250720230745);
INSERT INTO public."schema_migrations" (version) VALUES (20250721102600);
INSERT INTO public."schema_migrations" (version) VALUES (20250721183600);
INSERT INTO public."schema_migrations" (version) VALUES (20250722000000);
INSERT INTO public."schema_migrations" (version) VALUES (20250722100000);
