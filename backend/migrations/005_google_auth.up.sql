-- Google Sign-In: persist the federated identity so accounts can link by
-- Google's stable subject id (more reliable than email) and so we can tell how
-- an account authenticates.
--
-- auth_provider defaults to 'password' so existing rows (email/password signups)
-- are classified correctly without a backfill. google_sub is the Google account
-- id (the ID token "sub" claim): NULL for password accounts, UNIQUE so one
-- Google account maps to exactly one user. UNIQUE on a nullable column still
-- permits many NULLs, so password accounts are unaffected.
ALTER TABLE users
  ADD COLUMN auth_provider ENUM('password','google') NOT NULL DEFAULT 'password' AFTER password_hash,
  ADD COLUMN google_sub    VARCHAR(255) NULL AFTER auth_provider,
  ADD CONSTRAINT uq_users_google_sub UNIQUE (google_sub);
