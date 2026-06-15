-- Restore the UNIQUE constraint on users.phone (re-creating the index named
-- `phone` to match 001's inline definition). Note: rolling back will fail if
-- duplicate phone values exist by then — dedupe before migrating down.
ALTER TABLE users
  ADD UNIQUE INDEX phone (phone);
