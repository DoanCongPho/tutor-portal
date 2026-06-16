-- 004_student_invites: parents connect to a child via an invite code (the
-- "Add Child" / "My Children" mockups). A student row is created in `pending`
-- status carrying a generated invite_code + expiry; it moves to `connected`
-- once the code is accepted, at which point user_id links the child's own
-- account (NULL until then). school is shown in the My Children list.
ALTER TABLE students
  ADD COLUMN school            VARCHAR(255)                          AFTER grade,
  ADD COLUMN status            ENUM('pending','connected') NOT NULL DEFAULT 'pending' AFTER school,
  ADD COLUMN user_id           BIGINT UNSIGNED NULL                  AFTER status,
  ADD COLUMN invite_code       VARCHAR(20) NULL                      AFTER user_id,
  ADD COLUMN invite_expires_at DATETIME NULL                         AFTER invite_code,
  ADD COLUMN updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at,
  ADD INDEX idx_students_invite_code (invite_code),
  ADD CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(id);
