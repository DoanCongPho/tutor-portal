# Frontend (Flutter)

Flutter client for the tutor matching platform. iOS + Android only (per `docs/prd.md` §4).

The Dart side is scaffolded but the Flutter SDK has not been installed on this
machine yet — `android/`, `ios/`, and the package cache are missing, which is
why your IDE shows "package not found" errors. They all go away after the
bootstrap below.

## Bootstrap

```bash
# 1. Install Flutter (see https://docs.flutter.dev/get-started/install)
# 2. From this directory:
flutter create \
  --project-name tutor_portal \
  --org com.tutorportal \
  --platforms=ios,android \
  .                               # generates android/, ios/, .metadata; skips existing files
flutter pub get                   # resolves the deps in pubspec.yaml
```

`make flutter-bootstrap` and `make flutter-get` at the repo root run the same
two commands.

## Run

The default API URL targets the **Android emulator** (`10.0.2.2:8080` ⇢
host). Override for other targets via `--dart-define`:

```bash
# Android emulator — backend running on host
flutter run

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1

# Physical device on same Wi-Fi (replace with your machine's LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8080/api/v1
```

For physical devices the backend's `make run` already binds `0.0.0.0:8080`, so
no Go-side change is needed. iOS requires an App Transport Security exception
for plain HTTP — add `NSAppTransportSecurity > NSAllowsArbitraryLoads = true`
to `ios/Runner/Info.plist` for local dev only.

## Layout

```
lib/
  main.dart                       — runApp(ProviderScope(TutorPortalApp))
  app.dart                        — MaterialApp.router + theme
  core/
    config/app_config.dart        — apiBaseUrl, timeout (compile-time)
    api/api_client.dart           — http wrapper, JSON encode/decode, Bearer
    api/api_exception.dart        — typed error class
    router/app_router.dart        — go_router with auth-aware redirect
    theme/app_theme.dart          — Material 3 light + dark
    storage/secure_storage.dart   — flutter_secure_storage wrapper
  features/
    auth/
      data/
        auth_api.dart             — HTTP calls to /api/v1/auth/*
        token_storage.dart        — persist access/refresh + cached user
        auth_repository.dart      — orchestrates api + storage
      domain/
        user.dart                 — AppUser model (mirrors UserDTO)
      presentation/
        auth_controller.dart      — Riverpod Notifier (state + actions)
        login_screen.dart         — phone-only "send code"
        register_screen.dart      — phone + name + parent/tutor toggle
        verify_otp_screen.dart    — 6-digit input, routes to /home on success
        home_screen.dart          — placeholder post-login landing
test/widget_test.dart             — boots the app, asserts login renders
```

## How the auth flow is wired

1. App starts → `AuthController.build()` returns empty state, then async-loads
   any persisted user from secure storage. The router's `redirect` watches
   `user.id` and pushes you to `/home` if a session is restored.
2. Phone + (for register) name/role → `startLogin` / `startRegistration` →
   backend returns 202 → controller flips `otpSent = true`. The screen
   navigates to `/verify` only if no error was raised.
3. 6-digit code → `verifyOtp` → `verifyLogin` or `verifyRegistration` based on
   the pending flow → tokens + user persisted → state updates → router
   redirects to `/home`.
4. Logout via the AppBar icon clears storage and resets state; router sends
   you back to `/login`.

## What's deliberately NOT here yet

- **Auto-refresh on 401**: the `http` client doesn't intercept yet. When a
  feature first calls an authenticated endpoint, add a wrapper that catches
  `ApiException.isUnauthorized`, calls `AuthRepository.refresh()`, and retries
  once. The wiring is intentionally simple to avoid premature abstraction.
- **Form-field niceties**: country code picker, paste-the-SMS autofill,
  resend-OTP timer. The backend re-sends a fresh code each time `start` is
  called, so a resend button is a trivial controller method.
- **Localization** (vi + en): pinned skill `flutter-setup-localization`
  exists; wire it when you add the second feature.
- **Real OAuth (Google/Apple)**: deferred for v1 same as the backend side.

## Available skills

The repo pins a Flutter skill bundle in `skills-lock.json` covering routing,
JSON serialization, http, widget/integration tests, localization, responsive
layout, architecture best practices. Prefer invoking the relevant `flutter-*`
skill over writing patterns from scratch.
