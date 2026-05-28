# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

```
/                       — root: docker-compose.yml, nginx/, CLAUDE.md
/docs                   — PRD, SAD, use-case spec (authoritative product/architecture spec)
/backend                — Go API (module: github.com/DoanCongPho/tutor-portal/backend)
/frontend               — Flutter client (not bootstrapped yet — see frontend/README.md)
/nginx                  — reverse proxy config used by docker-compose
/.agents/skills/        — pinned Flutter skill bundle (used via skills-lock.json)
```

The backend module is fully scaffolded (compiles + vets clean). The frontend
is a placeholder — run `flutter create .` inside `frontend/` once Flutter is
installed locally; instructions are in `frontend/README.md`.

## Authoritative Specs

`docs/prd.md`, `docs/sad.md`, and `docs/use-case-spec.md` are the source of truth.
Read them end to end before touching a feature. When user requests contradict
the docs, surface the contradiction rather than silently picking a side.

`docs/sad.md` §11 is the schema spec; `backend/migrations/001_init.up.sql` is
a verbatim copy. Keep them in sync — if one changes, update the other in the
same commit, and write the reverse in the matching `.down.sql`.

## Commands

The root `Makefile` is the canonical entry point — `make help` lists every
target with a short description. Prefer it over raw `go`/`flutter`/`docker`
invocations so command shapes stay consistent.

Most common targets:

```bash
make run                # start the API server (APP_PORT=8080)
make build              # go build ./...
make vet                # go vet ./...
make test               # go test ./...
make tidy               # go mod tidy
make ci                 # vet + test (what CI should run)

make up                 # docker compose up --build -d (full stack)
make down               # docker compose down
make logs               # follow all service logs

make flutter-bootstrap  # one-time `flutter create .` inside frontend/
make flutter-run        # flutter run
make flutter-test       # flutter test
```

For a single backend package or a single test, drop into the module directly:

```bash
cd backend && go test ./internal/booking
cd backend && go test -run TestX ./internal/booking
```

Before `make up` works, copy the env template: `cp backend/.env.example backend/.env`
and fill in secrets. A health check is wired at `GET /api/v1/health` for
liveness probing.

## Migrations

Versioned with **golang-migrate** naming — every migration ships as a pair:

```
backend/migrations/
  001_init.up.sql      # forward
  001_init.down.sql    # rollback (drop tables in reverse FK order)
  002_<name>.up.sql
  002_<name>.down.sql
  ...
```

Workflow:

```bash
brew install golang-migrate                   # one-time
make migrate-create NAME=add_referrals        # scaffold next pair
# ...edit the generated .up.sql and .down.sql...
make migrate-up                               # apply forward
make migrate-down                             # roll back the latest
make migrate-status                           # current applied version
make migrate-force V=1                        # recover from a "dirty" state
```

Rules:

- **Every up file must have a paired down file** that fully reverses it. No
  one-way migrations.
- **Never edit a migration that has been applied** anywhere shared (CI, staging,
  prod). Write a new migration instead.
- The `migrate` CLI runs from the host. `make up` exposes MySQL on
  `DB_HOST_PORT` (default 3306) precisely so this works. From inside the docker
  network use `db:3306`; from the host use `127.0.0.1:3306`.
- `make stack-up` brings the whole stack up and waits for MySQL to be healthy
  before applying migrations — use this for a from-scratch local boot.
- DSN comes from `backend/.env` via `-include` in the Makefile. Override
  ad-hoc: `make migrate-up DATABASE_URL='mysql://user:pass@tcp(host:port)/db'`.

## Planned Architecture

**Stack:** Flutter (iOS + Android) client → Nginx → Go API → MySQL 8 + Redis 7;
AWS S3 for files; FCM for push; VNPay/MoMo/ZaloPay for payments. API is REST
under `/api/v1/`.

**Backend layering — strict, do not cross.** Every feature module under
`backend/internal/<feature>/` has the same files: `model.go`, `repository.go`,
`service.go`, `handler.go`, `dto.go`, `errors.go`, `routes.go`, `module.go`
(+ optional `helpers.go`). Dependency direction is fixed:

```
Handler → Service → Repository → Model → MySQL (via GORM)
             ↓
          Adapters (S3 / FCM / Payment) and Redis
```

Enforce these rules when writing or reviewing code:

- Handler **never** touches GORM or writes SQL — HTTP parsing/formatting only.
- Repository **never** contains business rules or permission checks — pure data access.
- Service **never** reads `gin.Context` or writes HTTP responses — return values + errors only.
- DTOs are API contract structs, **not** domain models. Don't pass DTOs into the repository.
- Adapters (S3, FCM, payment gateways) under `backend/pkg/` are consumed by services, never by handlers.
- `notification` module has no HTTP handler — it is an internal service injected into other modules. No feature calls FCM directly.

**Module wiring** lives in each `module.go` — that is the only place that
constructs `repo → service → handler` and injects cross-module dependencies
(e.g., booking module receives `PaymentService` and `NotificationService`).

## Planned Dependencies (not yet declared in go.mod)

The scaffold builds on stdlib only so it compiles before any external deps are
chosen. When implementing features, add these per `docs/sad.md`:

- Web framework: **Gin** (`github.com/gin-gonic/gin`) — referenced throughout the SAD.
- ORM: **GORM** (`gorm.io/gorm`, `gorm.io/driver/mysql`).
- Redis: `github.com/redis/go-redis/v9`.
- JWT: pick one — `github.com/golang-jwt/jwt/v5`.
- AWS S3: `github.com/aws/aws-sdk-go-v2/service/s3`.
- FCM: `firebase.google.com/go/v4`.

Add them with `go get` then run `go mod tidy`. Don't pre-declare deps you
aren't actually importing — `go mod tidy` will strip them anyway.

## Critical Domain Rules (easy to get wrong)

From `docs/prd.md` and `docs/sad.md`. Failing any of these breaks the product:

- **Tutor subjects are rows, not a string.** A tutor teaching Math at high
  school and university is two rows in `tutor_subjects`. Subject/level use a
  controlled vocabulary, not free text. Search joins through this table.
- **Only `VERIFIED` tutors with `is_accepting=true` appear in search.** Apply
  both filters in every search query.
- **Concurrent bookings:** a parent may have up to 3 `PENDING` bookings for the
  *same slot* across different tutors. When one confirms, the others move to
  `CANCELLED_BY_MATCH` and their escrow is refunded immediately.
  `CANCELLED_BY_MATCH` must not affect tutor reliability score.
- **Escrow lifecycle:** funds are locked at booking **creation** (`PENDING`),
  not at confirmation. Refunds happen on every cancel path. Release happens
  24h after `COMPLETED` via a Redis-delayed job; the job is cancelled if a
  dispute is raised inside the window.
- **Cancellation refund table** (see `docs/prd.md` §5.7) varies by who cancels
  and timing — encode it once in the service layer, do not duplicate.
- **Booking status enum is exhaustive.** All states: `pending`, `confirmed`,
  `in_progress`, `completed`, `paid`, `disputed`, `refunded`,
  `cancelled_by_tutor`, `cancelled_by_parent`, `cancelled_by_match`,
  `cancelled_by_timeout`. Don't collapse the cancel subtypes — reporting and
  reliability scoring depend on the distinction.
- **Slot concurrency:** pessimistic lock on the schedule slot at booking
  confirmation (per `docs/sad.md` §12).
- **Reviews unlock only at `PAID`**, one per booking; updating `rating_avg`
  on `tutor_profiles` is part of the review write.
- **Timezone:** store UTC, display Asia/Ho_Chi_Minh. MySQL charset is `utf8mb4`
  throughout for Vietnamese support.
- **File uploads:** 20 MB cap, PDF/JPG/PNG/DOCX only. Enforce in the service
  layer before hitting S3.

## Flutter Client Skills

The client side has a pinned skill bundle in `skills-lock.json` covering:
integration/widget tests, widget previews, responsive layout, layout fixes,
JSON serialization, declarative routing, localization, HTTP, and architecture
best practices. When working on the Flutter app, prefer invoking the relevant
`flutter-*` skill instead of writing patterns from scratch — they encode the
architectural choices already made for this project.
