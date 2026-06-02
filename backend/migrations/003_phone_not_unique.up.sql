-- Phone is no longer a unique identity. It is optional contact info (email is
-- the login identity), and multiple accounts may legitimately share a number
-- (e.g. a parent and their student, or family members). Drop the UNIQUE index.
--
-- The inline `phone VARCHAR(20) UNIQUE` in 001 created an index named `phone`.
ALTER TABLE users
  DROP INDEX phone;
