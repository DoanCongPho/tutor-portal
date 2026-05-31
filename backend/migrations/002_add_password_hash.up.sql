-- Auth moves from phone+OTP to phone+password (see docs/prd.md §auth).
-- bcrypt hashes are 60 chars; VARCHAR(255) leaves room for future cost/algorithm bumps.
-- DEFAULT '' so the column can be added NOT NULL even if rows already exist;
-- the service always writes a real hash on register, so '' only ever means
-- "legacy row with no password" and login will reject it.
ALTER TABLE users
  ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT '' AFTER email;
