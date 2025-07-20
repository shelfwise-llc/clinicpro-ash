-- Create admin_bypass_doctors table
CREATE TABLE IF NOT EXISTS admin_bypass_doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  specialty TEXT,
  bio TEXT,
  active BOOLEAN DEFAULT TRUE,
  years_of_experience INTEGER,
  consultation_fee DECIMAL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create admin_bypass_patients table
CREATE TABLE IF NOT EXISTS admin_bypass_patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT,
  medical_history TEXT,
  active BOOLEAN DEFAULT TRUE,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create admin_bypass_appointments table
CREATE TABLE IF NOT EXISTS admin_bypass_appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES admin_bypass_doctors(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES admin_bypass_patients(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled',
  reason TEXT,
  notes TEXT,
  diagnosis TEXT,
  prescription TEXT,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS admin_bypass_doctors_last_name_idx ON admin_bypass_doctors(last_name);
CREATE INDEX IF NOT EXISTS admin_bypass_patients_last_name_idx ON admin_bypass_patients(last_name);
CREATE INDEX IF NOT EXISTS admin_bypass_appointments_doctor_id_idx ON admin_bypass_appointments(doctor_id);
CREATE INDEX IF NOT EXISTS admin_bypass_appointments_patient_id_idx ON admin_bypass_appointments(patient_id);
CREATE INDEX IF NOT EXISTS admin_bypass_appointments_date_idx ON admin_bypass_appointments(date);
