# Tutor Matching Platform

A mobile-first platform that connects parents with **verified** tutors and
handles discovery, scheduling, payments (escrow), and learning materials
end-to-end. It serves four roles: **Parent**, **Tutor**, **Student**, and
**Admin** (internal).

**Stack:** Flutter client → Go REST API (`/api/v1/`) → MySQL 8 + Redis 7.
(AWS S3 for files, FCM for push, and VNPay/MoMo/ZaloPay for payments are planned
integrations.)

> **Authoritative specs** live in [`docs/`](docs/) — `prd.md` (product),
> `sad.md` (architecture + DB schema §11), and `use-case-spec.md`. Engineering
> conventions are in [`CLAUDE.md`](CLAUDE.md).

> ⚠️ **Local-only for now.** This guide covers running everything **directly on
> your machine** (local MySQL + Redis + Go + Flutter). Docker files
> (`docker-compose.yml`, `backend/Dockerfile`) exist but **have not been tested
> yet** — use the local steps below.

---

## Repository layout

```
/                 Makefile, docker-compose.yml (untested), CLAUDE.md
/docs             PRD, SAD, use-case spec (source of truth)
/backend          Go API — module github.com/DoanCongPho/tutor-portal/backend
/frontend         Flutter client
/backend/migrations  golang-migrate SQL pairs (NNN_name.up.sql / .down.sql)
```

---

## Prerequisites

Install these locally:

| Tool | Version | Install (macOS) |
|---|---|---|
| [Go](https://go.dev/dl/) | 1.25+ | `brew install go` |
| [MySQL](https://dev.mysql.com/) | 8.0 | `brew install mysql` |
| [Redis](https://redis.io/) | 7 | `brew install redis` |
| [Flutter](https://docs.flutter.dev/get-started/install) | 3.27+ (Dart 3.6+) | `brew install --cask flutter` |
| [golang-migrate](https://github.com/golang-migrate/migrate) | latest | `brew install golang-migrate` |

The root **`Makefile`** is the entry point — `make help` lists every target.

---

## Setup (run everything locally)

### 1. Start MySQL and create the database

```bash
brew services start mysql        # start a local MySQL server

mysql -u root -p                 # then run the SQL below
```
```sql
CREATE DATABASE tutor_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'change_me';
GRANT ALL PRIVILEGES ON tutor_platform.* TO 'app_user'@'localhost';
FLUSH PRIVILEGES;
```

### 2. Start Redis

```bash
brew services start redis        # the API needs Redis for OTP/session state
```

### 3. Configure `backend/.env` to point at your **local** MySQL + Redis

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env` — the template defaults to the Docker hostnames (`db`,
`redis`), so for a local run you **must** change the hosts to `127.0.0.1` and
fill in your DB credentials and a JWT secret:

```dotenv
APP_PORT=8080

# Database — point at your LOCAL MySQL
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=tutor_platform
DB_USER=app_user
DB_PASSWORD=change_me        # the password you set in step 1

# Redis — point at your LOCAL Redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# Auth
JWT_SECRET=some_long_random_string
```

(AWS / FCM / payment keys can stay blank for local development.)

### 4. Apply database migrations

```bash
make migrate-up        # builds the DSN from backend/.env (host 127.0.0.1)
make migrate-status    # should show the latest version
```

---

## Run

### Backend API

```bash
make run               # = cd backend && go run ./cmd/api  (loads backend/.env)
```

It must be able to reach MySQL and Redis or it exits on startup. Verify:

```bash
curl http://localhost:8080/api/v1/health     # -> {"status":"ok"}
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
```

Then launch on **one** of:

**Android emulator** — works with the default API URL (`10.0.2.2` is the
emulator's alias for your host machine):

```bash
flutter run -d emulator-5554        # use your emulator id from `flutter devices`
```

**Chrome (web)** — the browser runs on the host, so point the app at
`localhost` via `--dart-define` (one line):

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

> **Note for the web target:** the API enables CORS (all origins in dev), so
> Chrome works end-to-end as long as you pass the `--dart-define` above and the
> backend is running.

---

## Migrations

Schema changes ship as a paired `up`/`down` under `backend/migrations/`. Never
edit a migration that has already been applied — add a new one.

```bash
make migrate-create NAME=add_xyz     # scaffold the next NNN_*.up/.down pair
make migrate-up                      # apply pending migrations
make migrate-down                    # roll back the latest (one step)
make migrate-status                  # current version
make migrate-force V=1               # recover from a "dirty" state
```

---

## Handy Make targets

```bash
make build     # go build ./...
make vet       # go vet ./...
make test      # go test ./...
make ci        # vet + test
make run       # run the API locally
make flutter-run       # flutter run
make flutter-analyze   # flutter analyze
make flutter-test      # flutter test
```
