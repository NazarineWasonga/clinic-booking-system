-- Clinic Booking System Schema (MySQL)
-- Deliverable: CREATE TABLE statements for a full relational database
-- Storage engine: InnoDB (supports FK constraints, transactions)

SET FOREIGN_KEY_CHECKS = 0;

-- Clinics (multiple physical locations)
CREATE TABLE clinics (
  clinic_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  address VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  phone VARCHAR(30),
  email VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE (name, address)
) ENGINE=InnoDB;

-- Roles for staff/users (admin, receptionist, doctor, nurse)
CREATE TABLE roles (
  role_id INT AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

-- Users / Staff (doctors, receptionists, admins)
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_id INT NOT NULL,
  role_id INT NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(30),
  hire_date DATE,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Doctors table (subset of users with medical-specific fields)
CREATE TABLE doctors (
  doctor_id INT PRIMARY KEY,
  user_id INT NOT NULL UNIQUE,
  license_number VARCHAR(50) NOT NULL UNIQUE,
  specialty VARCHAR(100),
  bio TEXT,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Patients
CREATE TABLE patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_id INT NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE,
  gender ENUM('Male','Female','Other') DEFAULT 'Other',
  phone VARCHAR(30),
  email VARCHAR(150),
  address VARCHAR(255),
  emergency_contact_name VARCHAR(150),
  emergency_contact_phone VARCHAR(30),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Services offered (consultation, x-ray, vaccination etc.)
CREATE TABLE services (
  service_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  code VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  base_price DECIMAL(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB;

-- Many-to-many: which doctor offers which services
CREATE TABLE doctor_services (
  doctor_id INT NOT NULL,
  service_id INT NOT NULL,
  consultation_duration_minutes INT NOT NULL DEFAULT 30,
  PRIMARY KEY (doctor_id, service_id),
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Rooms / Facilities in a clinic
CREATE TABLE rooms (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  capacity INT DEFAULT 1,
  notes VARCHAR(255),
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  UNIQUE (clinic_id, name)
) ENGINE=InnoDB;

-- Appointment statuses
CREATE TABLE appointment_statuses (
  status_id INT AUTO_INCREMENT PRIMARY KEY,
  status_name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- Appointments
CREATE TABLE appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_id INT NOT NULL,
  patient_id INT NOT NULL,
  doctor_id INT,
  room_id INT,
  service_id INT,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NOT NULL,
  status_id INT NOT NULL,
  created_by INT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL,
  FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE SET NULL,
  FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE SET NULL,
  FOREIGN KEY (status_id) REFERENCES appointment_statuses(status_id) ON DELETE RESTRICT,
  FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Indexes to help booking queries
CREATE INDEX idx_appointments_schedule ON appointments (clinic_id, scheduled_start);
CREATE INDEX idx_appointments_patient ON appointments (patient_id);
CREATE INDEX idx_appointments_doctor ON appointments (doctor_id);

-- To support many-to-many services added to an appointment (e.g., multiple services in one visit)
CREATE TABLE appointment_services (
  appointment_id INT NOT NULL,
  service_id INT NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (appointment_id, service_id),
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Medical records / notes for appointments
CREATE TABLE medical_notes (
  note_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL,
  patient_id INT NOT NULL,
  authored_by INT,
  note_text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (authored_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Prescriptions
CREATE TABLE prescriptions (
  prescription_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL,
  patient_id INT NOT NULL,
  prescribed_by INT NOT NULL,
  issued_date DATE NOT NULL DEFAULT (CURRENT_DATE),
  notes TEXT,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (prescribed_by) REFERENCES doctors(doctor_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Medications (catalog)
CREATE TABLE medications (
  medication_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  manufacturer VARCHAR(150),
  unit VARCHAR(50),
  UNIQUE (name)
) ENGINE=InnoDB;

-- Prescription lines (many medications per prescription)
CREATE TABLE prescription_items (
  prescription_id INT NOT NULL,
  medication_id INT NOT NULL,
  dosage VARCHAR(100),
  duration_days INT,
  instructions TEXT,
  PRIMARY KEY (prescription_id, medication_id),
  FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
  FOREIGN KEY (medication_id) REFERENCES medications(medication_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Billing: invoices
CREATE TABLE invoices (
  invoice_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_id INT NOT NULL,
  patient_id INT NOT NULL,
  appointment_id INT,
  issue_date DATE NOT NULL DEFAULT (CURRENT_DATE),
  due_date DATE,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status ENUM('Pending','Paid','Cancelled') DEFAULT 'Pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Invoice lines
CREATE TABLE invoice_items (
  invoice_item_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(10,2) AS (quantity * unit_price) STORED,
  FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Payments
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  payment_date DATE NOT NULL DEFAULT (CURRENT_DATE),
  amount DECIMAL(10,2) NOT NULL,
  method ENUM('Cash','Card','MobileMoney','Insurance') NOT NULL,
  reference VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Insurance providers
CREATE TABLE insurance_providers (
  provider_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  contact_info VARCHAR(255)
) ENGINE=InnoDB;

-- Optional: patient insurance mapping
CREATE TABLE patient_insurance (
  patient_id INT NOT NULL,
  provider_id INT NOT NULL,
  policy_number VARCHAR(100) NOT NULL,
  PRIMARY KEY (patient_id, provider_id, policy_number),
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (provider_id) REFERENCES insurance_providers(provider_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Audit trail for users' actions
CREATE TABLE audit_logs (
  log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(100) NOT NULL,
  target_table VARCHAR(100),
  target_id VARCHAR(100),
  details TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Seed some appointment statuses
INSERT INTO appointment_statuses (status_name) VALUES
('Scheduled'), ('Checked In'), ('In Progress'), ('Completed'), ('Cancelled');

SET FOREIGN_KEY_CHECKS = 1;

-- End of schema
