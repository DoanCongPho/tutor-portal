# CLAUDE.md — Frontend

Rules for the Flutter client. These distill the 10 skill bundles in
`.agents/skills/flutter-*/SKILL.md` (which are the source of truth — read the
relevant `SKILL.md` before doing the matching kind of work) and lock in the
choices this project has already made.

## Architecture

- **Feature-first.** All feature code under `lib/features/<feature>/{data,domain,presentation}/`. Cross-feature infra under `lib/core/`.
- **State management:** Riverpod 2 (`Notifier` / `AsyncNotifier`). The architecture skill prescribes MVVM with `ChangeNotifier`; treat that as "expose immutable state to widgets via a listenable" — Riverpod's `Notifier` satisfies it with better DI and async support.
- **Repository pattern.** Data sources (HTTP, secure storage, future SQLite) sit behind a `XxxRepository` injected via a Riverpod `Provider`. Controllers never call APIs or storage directly.
- **No HTTP in widgets.** Widgets call controller methods; controllers call repositories; repositories call APIs/storage. Crossing this line is the #1 thing to push back on in review.
- **Immutable state.** Controller state objects should be `const`-constructible. Use a `copyWith` for partial updates; never mutate in place.

## Routing

- **`go_router` only.** Mounted via `MaterialApp.router` in `lib/app.dart`. Routes constants live in `core/router/app_router.dart::AppRoutes`.
- **Auth gating via `refreshListenable`**, not manual navigation after sign-in. The `_AuthRouterListener` already bridges Riverpod → go_router. Add new gated routes to the existing `redirect` callback, don't sprinkle `context.go(...)` after every auth state change.
- **Nested navigation** (bottom nav, role-aware shells) uses `StatefulShellRoute.indexedStack`. Not yet wired — add when the second authed feature lands.
- **Deep linking** (Android intent filter, iOS `FlutterDeepLinkingEnabled`, asset-links / AASA hosting) is deferred until we ship a beta.

## HTTP

- **`http` package only**, not Dio. The wrapper is `core/api/api_client.dart`.
- Always `Uri.parse(...)`. Always validate status and throw `ApiException` on non-2xx — **never return null** to signal failure.
- For payloads larger than ~50 KB or with deeply nested JSON, parse off the UI thread with `compute(topLevelFn, bytes)`.
- Use `HttpHeaders.authorizationHeader` constants over string literals when adding headers manually.
- **No auto-refresh on 401 yet.** Feature that first hits an authed endpoint should wrap the call: catch `ApiException.isUnauthorized` → `AuthRepository.refresh()` → retry once. Then promote that wrapper into `ApiClient` once a second feature needs it.

## JSON serialization

- Manual `fromJson` factory + `toJson` method on each model. Always cast `jsonDecode(body) as Map<String, dynamic>` — never `as dynamic`.
- **Switch to `json_serializable` + `build_runner`** when we hit 5+ models or any polymorphic model (e.g., notification payload variants). The skill names those exact packages.
- Generated `.g.dart` files are already excluded by `analysis_options.yaml`.

## Layout

- Adapt to width via `LayoutBuilder` + `constraints.maxWidth`. **Do not** branch on `MediaQuery.size.width` or device orientation.
- Constrain top-level content with `ConstrainedBox(maxWidth: 480)` + `Center` on screens where a form/centered card shouldn't stretch to tablet width.
- Long lists: **always** use `ListView.builder` / `GridView.builder`. Never spread items into `Column` inside a `SingleChildScrollView`.
- Constraint rule: constraints flow down, sizes flow up, parent sets position. Need a `TextField` to fill a `Row`? Wrap in `Expanded`. Need a `ListView` inside a `Column`? Wrap in `Expanded`.
- Foldables / orientation: **do not lock orientation**. The layout-issues skill calls this out.

## Localization

- Will use `flutter_localizations` + `intl` + ARB files under `lib/l10n/` (`app_en.arb`, `app_vi.arb`). Until then, English strings inline, **but never embed user-facing strings inside service/controller logic** — keep them in widgets so the eventual extraction is a 1-file change.
- When localization lands, switch the font to **Be Vietnam Pro** (Google Fonts) — Roboto's diacritic spacing drifts on `ậ`, `ặ`, `ỹ`.

## Testing

- Widget tests in `test/`, integration tests in `integration_test/`.
- **Add `ValueKey` to anything you intend to find from a test.** `find.byKey(const ValueKey('login_phone_field'))` survives copy changes; `find.text('Phone number')` doesn't.
- For scrolling lists, use `scrollUntilVisible` rather than expecting target items in the initial viewport.
- Indefinite animations (e.g., `CircularProgressIndicator` left on screen) hang `pumpAndSettle()`. Either pump a finite number of frames or `await tester.pump()` with a duration.

## Widget previews

- Annotate sample widgets with `@Preview` (top-level function, static method, or const-able public constructor). Useful for iterating on a screen without booting the full app + Riverpod scope.
- Previews **cannot** call `dart:io`, native channels, or use private callbacks. If a screen needs Riverpod, wrap with a `ProviderScope` containing overrides for any provider that touches platform code.

## Design system

- **`docs/design-system.md`** is the source of truth for colors, type, spacing, shape, and component conventions.
- The theme reads from a single brand seed in `core/theme/app_theme.dart`. **Never hardcode hex colors in widgets.** Read from `Theme.of(context).colorScheme.{primary, onSurface, surfaceContainerHigh, ...}`.
- Default component styles (FilledButton 56dp, OutlinedButton 48dp, 14dp radius, filled input on `surfaceContainerHigh`) are set theme-wide. Override per-call only when a specific screen genuinely needs to deviate, and prefer adding a documented variant to the design doc over a one-off.

## Gotchas surfaced by the skills

- `pumpAndSettle()` never returns while an infinite animation is on screen.
- Don't lock device orientation — layouts must work portrait + landscape, and breaking foldables is a real risk.
- Conditional imports are how to mock native APIs in preview / test mode.
- Large JSON on the UI thread = jank. `compute()`.
- `Uri.parse` not string concatenation. Encode query params via `Uri.queryParameters`.
