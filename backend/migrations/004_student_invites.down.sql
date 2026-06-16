-- Reverses 004_student_invites. Drop the FK and index before the columns.
ALTER TABLE students
  DROP FOREIGN KEY fk_students_user,
  DROP INDEX idx_students_invite_code,
  DROP COLUMN invite_expires_at,
  DROP COLUMN invite_code,
  DROP COLUMN user_id,
  DROP COLUMN status,
  DROP COLUMN school,
  DROP COLUMN updated_at;
