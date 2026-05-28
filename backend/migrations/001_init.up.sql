-- 001_init: initial schema.
-- Source of truth: docs/sad.md §11. Keep this file in sync with that section.
-- Apply with: make migrate-up

CREATE TABLE users (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role        ENUM('tutor','parent','student','admin') NOT NULL,
  name        VARCHAR(255) NOT NULL,
  phone       VARCHAR(20) UNIQUE,
  email       VARCHAR(255) UNIQUE,
  avatar_url  VARCHAR(500),
  status      ENUM('active','suspended') NOT NULL DEFAULT 'active',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tutor_profiles (
  id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id             BIGINT UNSIGNED NOT NULL UNIQUE,
  hourly_rate         DECIMAL(10,0) NOT NULL,
  bio                 TEXT,
  is_accepting        BOOLEAN NOT NULL DEFAULT TRUE,
  verification_status ENUM('pending_review','requires_documents',
                           'verified','rejected') NOT NULL DEFAULT 'pending_review',
  rating_avg          DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  rating_count        INT UNSIGNED NOT NULL DEFAULT 0,
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tutor_subjects (
  id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tutor_id BIGINT UNSIGNED NOT NULL,
  subject  VARCHAR(100) NOT NULL,
  level    ENUM('primary','middle_school','high_school','university') NOT NULL,
  FOREIGN KEY (tutor_id) REFERENCES tutor_profiles(id),
  UNIQUE KEY uq_tutor_subject_level (tutor_id, subject, level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tutor_documents (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tutor_id    BIGINT UNSIGNED NOT NULL,
  doc_type    ENUM('degree','certificate','national_id') NOT NULL,
  file_url    VARCHAR(500) NOT NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  verified_at DATETIME,
  admin_note  TEXT,
  FOREIGN KEY (tutor_id) REFERENCES tutor_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE schedules (
  id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tutor_id     BIGINT UNSIGNED NOT NULL,
  day_of_week  TINYINT NOT NULL COMMENT '0=Sunday 6=Saturday',
  start_time   TIME NOT NULL,
  end_time     TIME NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (tutor_id) REFERENCES tutor_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE students (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_id  BIGINT UNSIGNED NOT NULL,
  name       VARCHAR(255) NOT NULL,
  grade      VARCHAR(50),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bookings (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tutor_id      BIGINT UNSIGNED NOT NULL,
  student_id    BIGINT UNSIGNED NOT NULL,
  parent_id     BIGINT UNSIGNED NOT NULL,
  subject       VARCHAR(100) NOT NULL,
  level         ENUM('primary','middle_school','high_school','university') NOT NULL,
  slot_datetime DATETIME NOT NULL,
  duration_mins SMALLINT UNSIGNED NOT NULL DEFAULT 60,
  status        ENUM('pending','confirmed','in_progress','completed',
                     'paid','disputed','refunded',
                     'cancelled_by_tutor','cancelled_by_parent',
                     'cancelled_by_match','cancelled_by_timeout')
                NOT NULL DEFAULT 'pending',
  amount        DECIMAL(12,0) NOT NULL,
  platform_fee  DECIMAL(12,0),
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (tutor_id)   REFERENCES tutor_profiles(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (parent_id)  REFERENCES users(id),
  INDEX idx_tutor_status  (tutor_id, status),
  INDEX idx_parent_status (parent_id, status),
  INDEX idx_slot_datetime (slot_datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE materials (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tutor_id   BIGINT UNSIGNED NOT NULL,
  student_id BIGINT UNSIGNED NOT NULL,
  booking_id BIGINT UNSIGNED,
  type       ENUM('slide','note','assignment') NOT NULL,
  file_url   VARCHAR(500),
  title      VARCHAR(255) NOT NULL,
  deadline   DATETIME,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tutor_id)   REFERENCES tutor_profiles(id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (booking_id) REFERENCES bookings(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE submissions (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  assignment_id BIGINT UNSIGNED NOT NULL,
  student_id    BIGINT UNSIGNED NOT NULL,
  file_url      VARCHAR(500) NOT NULL,
  submitted_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status        ENUM('submitted','overdue') NOT NULL DEFAULT 'submitted',
  FOREIGN KEY (assignment_id) REFERENCES materials(id),
  FOREIGN KEY (student_id)    REFERENCES students(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE wallets (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    BIGINT UNSIGNED NOT NULL UNIQUE,
  balance    DECIMAL(14,0) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE transactions (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id        BIGINT UNSIGNED NOT NULL,
  type           ENUM('topup','escrow_lock','escrow_release',
                      'refund','withdrawal') NOT NULL,
  amount         DECIMAL(12,0) NOT NULL,
  ref_booking_id BIGINT UNSIGNED,
  gateway        VARCHAR(50),
  gateway_ref    VARCHAR(255),
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)        REFERENCES users(id),
  FOREIGN KEY (ref_booking_id) REFERENCES bookings(id),
  INDEX idx_user_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE reviews (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED NOT NULL UNIQUE,
  parent_id  BIGINT UNSIGNED NOT NULL,
  tutor_id   BIGINT UNSIGNED NOT NULL,
  rating     TINYINT UNSIGNED NOT NULL,
  comment    TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id),
  FOREIGN KEY (parent_id)  REFERENCES users(id),
  FOREIGN KEY (tutor_id)   REFERENCES tutor_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
