-- 001_init: rollback. Drops every table created in 001_init.up.sql.
-- Order is the reverse of creation so foreign-key dependents go first.
-- Apply with: make migrate-down

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS wallets;
DROP TABLE IF EXISTS submissions;
DROP TABLE IF EXISTS materials;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS schedules;
DROP TABLE IF EXISTS tutor_documents;
DROP TABLE IF EXISTS tutor_subjects;
DROP TABLE IF EXISTS tutor_profiles;
DROP TABLE IF EXISTS users;
