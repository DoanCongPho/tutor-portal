# Frontend (Flutter)

Flutter client for the tutor matching platform. iOS + Android only (per `docs/prd.md` §4).

## Bootstrap

Flutter is **not** scaffolded yet — this directory only contains the placeholder
folder for feature code. Install Flutter, then from this directory:

```bash
flutter create \
  --project-name tutor_portal \
  --org com.tutorportal \
  --platforms=ios,android \
  .
flutter pub get
```

`flutter create .` will generate `pubspec.yaml`, `lib/main.dart`, and the
`android/`, `ios/` platform folders alongside the existing `lib/features/` tree
without overwriting it.

## Layout

Feature-first under `lib/features/<feature>/` to mirror the backend modules in
`backend/internal/`. Suggested initial features:

| Feature | Covers (PRD / UC) |
|---|---|
| `auth` | UC-01 registration, login, OTP |
| `tutor_profile` | UC-12, UC-13 — own profile, schedule, accepting toggle |
| `tutor_search` | UC-03 — parent search & discovery |
| `booking` | UC-04, UC-05 |
| `materials` | UC-06, UC-07 |
| `wallet` | UC-14, UC-15 plus dispute (UC-09) |
| `reviews` | UC-11 |
| `notifications` | FCM device registration + in-app inbox |

Admin is mobile-only too per the PRD non-goals (no web in v1) — but it can stay
in a separate app or behind a role gate; do not co-mingle admin screens into
the parent/tutor flows.

## Available skills

This project pins a Flutter skill bundle in the repo root `skills-lock.json`.
When implementing features, prefer the relevant `flutter-*` skill (routing,
JSON serialization, http, widget tests, responsive layout, etc.) over writing
patterns from scratch.
