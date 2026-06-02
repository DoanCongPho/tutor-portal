# Tutor Matching Platform

A mobile-first platform that connects parents with **verified** tutors and
handles discovery, scheduling, payments (escrow), and learning materials
end-to-end. It serves four roles: **Parent**, **Tutor**, **Student**, and
**Admin** (internal).

**Stack:** Flutter client → Nginx → Go REST API (`/api/v1/`) → MySQL 8 + Redis 7,
with AWS S3 for files, FCM for push, and Vietnamese payment gateways
(VNPay / MoMo / ZaloPay). Everything runs locally via Docker Compose.

> **Authoritative specs** live in [`docs/`](docs/) — `prd.md` (product),
> `sad.md` (architecture + DB schema §11), and `use-case-spec.md`. Read those
> before changing a feature. Engineering conventions are in
> [`CLAUDE.md`](CLAUDE.md).

---

## Repository layout

```
/                 docker-compose.yml, Makefile, nginx/, CLAUDE.md
/docs             PRD, SAD, use-case spec (source of truth)
/backend          Go API — module github.com/DoanCongPho/tutor-portal/backend
/frontend         Flutter client (bootstrap with `make flutter-bootstrap`)
/nginx            reverse-proxy config used by docker-compose
/backend/migrations  golang-migrate SQL pairs (NNN_name.up.sql / .down.sql)
```

The backend is fully scaffolded (compiles + vets clean, exposes a health
check). The frontend is a placeholder until you run the one-time bootstrap.

---

## Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| [Go](https://go.dev/dl/) | 1.25+ | backend |
| [Docker](https://www.docker.com/) + Compose | latest | full local stack (MySQL, Redis, API, Nginx) |
| [Flutter](https://docs.flutter.dev/get-started/install) | 3.27+ (Dart 3.6+) | frontend |
| [golang-migrate](https://github.com/golang-migrate/migrate) | latest | DB migrations (`brew install golang-migrate`) |

The root **`Makefile`** is the canonical entry point — run `make help` to list
every target. Prefer it over raw `go`/`flutter`/`docker` commands.

---

## Setup

```bash
# 1. Create the backend env file from the template and fill in secrets
cp backend/.env.example backend/.env
#    At minimum set DB_PASSWORD, DB_ROOT_PASSWORD, and JWT_SECRET.
#    (AWS/FCM/payment keys can stay blank for local dev.)
```

---

## Run

### Option A — full stack in Docker (recommended)

Brings up MySQL, Redis, the API, and Nginx, waits for MySQL to be healthy, then
applies all migrations:

```bash
make stack-up        # = docker compose up --build -d  +  migrate-up
make logs            # follow service logs
make down            # stop and remove containers
```

Health check: `curl http://localhost:8080/api/v1/health` → `{"status":"ok"}`.

### Option B — backend on the host, infra in Docker

Useful for fast iteration on Go code:

```bash
make up              # start only the docker services (MySQL/Redis/...)
make migrate-up      # apply migrations (CLI runs from the host → 127.0.0.1:3306)
make run             # run the API in the foreground (loads backend/.env)
```

### Frontend (Flutter)

```bash
make flutter-bootstrap   # ONE-TIME: scaffolds the Flutter project (flutter create .)
make flutter-get         # flutter pub get
make flutter-run         # launch on the connected device/emulator
```

**API base URL per run target.** The Android emulator reaches the host at
`10.0.2.2`; web/desktop/iOS-simulator use `localhost`. Override at launch:

```bash
# web / desktop / iOS simulator
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1

# physical phone (same Wi-Fi) — use your PC's LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
```

---

## Migrations

Schema changes ship as a paired `up`/`down` under `backend/migrations/`
(golang-migrate). Never edit a migration that has already been applied — add a
new one.

```bash
make migrate-create NAME=add_referrals   # scaffold the next NNN_*.up/.down pair
make migrate-up                           # apply pending migrations
make migrate-down                         # roll back the latest (one step)
make migrate-status                       # current applied version
make migrate-force V=1                     # recover from a "dirty" state
```

Override the DSN ad-hoc:
`make migrate-up DATABASE_URL='mysql://user:pass@tcp(host:port)/db'`.

---

## Common Make targets

```bash
make build     # go build ./...
make vet       # go vet ./...
make test      # go test ./...
make ci        # vet + test (what CI runs)
make tidy      # go mod tidy
make fmt       # go fmt ./...
make flutter-test     # flutter test
make flutter-analyze  # flutter analyze
```

Run a single backend package or test directly:

```bash
cd backend && go test ./internal/tutor
cd backend && go test -run TestX ./internal/booking
```
