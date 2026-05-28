.PHONY: help build run test vet tidy fmt clean ci \
        flutter-bootstrap flutter-get flutter-run flutter-test flutter-analyze \
        up down logs ps stack-up \
        migrate-up migrate-down migrate-status migrate-create migrate-force

BACKEND  := backend
FRONTEND := frontend
GO       := go
FLUTTER  := flutter
COMPOSE  := docker compose
MIGRATE  := migrate

# Pull DB credentials from backend/.env when present (missing file is ignored).
-include $(BACKEND)/.env

# Defaults used when .env is absent. MIGRATE_HOST/PORT default to 127.0.0.1:DB_HOST_PORT
# because `make migrate-*` runs from the host, not from inside the docker network
# where DB_HOST=db.
DB_USER       ?= app_user
DB_PASSWORD   ?=
DB_NAME       ?= tutor_platform
DB_HOST_PORT  ?= 3306
MIGRATE_HOST  ?= 127.0.0.1
MIGRATE_PORT  ?= $(DB_HOST_PORT)
DATABASE_URL  ?= mysql://$(DB_USER):$(DB_PASSWORD)@tcp($(MIGRATE_HOST):$(MIGRATE_PORT))/$(DB_NAME)

.DEFAULT_GOAL := help

help:  ## List available targets
	@awk 'BEGIN { FS = ":.*##"; printf "Targets:\n" } \
	     /^[a-zA-Z0-9_.-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' \
	     $(MAKEFILE_LIST)

# ---------- Backend (Go) ----------

build:  ## Compile every backend package
	cd $(BACKEND) && $(GO) build ./...

run:  ## Run the API server in the foreground (loads backend/.env if present)
	cd $(BACKEND) && $(GO) run ./cmd/api

test:  ## Run backend tests
	cd $(BACKEND) && $(GO) test ./...

vet:  ## go vet all backend packages
	cd $(BACKEND) && $(GO) vet ./...

tidy:  ## go mod tidy
	cd $(BACKEND) && $(GO) mod tidy

fmt:  ## go fmt all backend packages
	cd $(BACKEND) && $(GO) fmt ./...

# ---------- Frontend (Flutter) ----------

flutter-bootstrap:  ## One-time: scaffold Flutter project files (preserves lib/features)
	cd $(FRONTEND) && $(FLUTTER) create --project-name tutor_portal --org com.tutorportal --platforms=ios,android .

flutter-get:  ## flutter pub get
	cd $(FRONTEND) && $(FLUTTER) pub get

flutter-run:  ## Launch the Flutter app on the connected device
	cd $(FRONTEND) && $(FLUTTER) run

flutter-test:  ## Run Flutter widget/unit tests
	cd $(FRONTEND) && $(FLUTTER) test

flutter-analyze:  ## flutter analyze
	cd $(FRONTEND) && $(FLUTTER) analyze

# ---------- Docker stack ----------

up:  ## Build and start the full docker compose stack (detached)
	$(COMPOSE) up --build -d

down:  ## Stop and remove docker compose containers
	$(COMPOSE) down

logs:  ## Follow logs for all services
	$(COMPOSE) logs -f

ps:  ## Show docker compose service status
	$(COMPOSE) ps

# ---------- Migrations (golang-migrate) ----------
# Requires the `migrate` CLI: brew install golang-migrate
# Override the DSN with: make migrate-up DATABASE_URL='mysql://user:pass@tcp(host:port)/db'

migrate-up:  ## Apply all pending migrations
	$(MIGRATE) -path $(BACKEND)/migrations -database "$(DATABASE_URL)" up

migrate-down:  ## Roll back the most recent migration (one step)
	$(MIGRATE) -path $(BACKEND)/migrations -database "$(DATABASE_URL)" down 1

migrate-status:  ## Show the current migration version
	$(MIGRATE) -path $(BACKEND)/migrations -database "$(DATABASE_URL)" version

migrate-create:  ## Scaffold a new migration pair. Usage: make migrate-create NAME=add_xyz
	@test -n "$(NAME)" || (echo "usage: make migrate-create NAME=<snake_case_name>" && exit 1)
	$(MIGRATE) create -ext sql -dir $(BACKEND)/migrations -seq $(NAME)

migrate-force:  ## Force the version (use only to recover from a dirty state). Usage: make migrate-force V=1
	@test -n "$(V)" || (echo "usage: make migrate-force V=<version>" && exit 1)
	$(MIGRATE) -path $(BACKEND)/migrations -database "$(DATABASE_URL)" force $(V)

# ---------- Composite ----------

ci: vet test  ## What CI would run on the backend (vet + test)

stack-up: up  ## Start docker stack and run migrations once MySQL is healthy
	@echo "waiting for MySQL to become healthy..."
	@until [ "$$($(COMPOSE) ps --format json db | grep -o '\"Health\":\"healthy\"')" = '"Health":"healthy"' ]; do sleep 2; done
	$(MAKE) migrate-up

clean:  ## Remove local build artefacts
	rm -f  $(BACKEND)/server
	rm -rf $(FRONTEND)/build $(FRONTEND)/.dart_tool
