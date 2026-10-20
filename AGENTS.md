# GatherMap — Agent Guide

Flutter app (Dart SDK `^3.11.4`, Flutter stable) backed by Supabase, organised
**feature-first with a clean-architecture core**:

```
lib/
├── main.dart          bootstrap only: Supabase.initialize → runApp
├── app/               MyApp, provider scope wiring, nav shell
├── core/              cross-feature code: state, error, di, routing, theme, widgets
├── data/supabase/     the Supabase client wrapper
├── models/            Supadart output (generated — never hand-edit)
└── features/<name>/   data/ → domain/ ← presentation/
```

Dependency rule inside a feature: `presentation → domain ← data`. Only
`data/` imports Supabase or `lib/models/`; `domain/` is plain Dart and
`presentation/` talks to repository interfaces.

## Commands

- `flutter pub get` — install deps.
- `flutter analyze` — must be clean; CI gate.
- `flutter test` — full suite (no `.env` or Supabase needed; tests never call the network).
- Single file: `flutter test test/features/events/presentation/event_controller_test.dart`
- Single test: `flutter test --plain-name "an event exactly at [now] counts as past"`
- Run the app: `flutter run --dart-define-from-file=.env`. Config is compile-time via `String.fromEnvironment` in `lib/main.dart`, so it must be passed at build/run time. `.env` is gitignored; it holds `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
- CI (`.github/workflows/dart.yml`, `main` branch): `flutter pub get` → `flutter analyze` → `flutter test`. The `dart format` check is present but commented out.

## Architecture notes

- **Dependency wiring lives in `lib/core/di/providers.dart`.** `AppDependencies` builds the concrete repositories; `buildProviderScope()` wraps the app in the `MultiProvider`. This is the only place that chooses an implementation. Constructing the graph performs no I/O — the `SupabaseService` resolves its client on first query — so **never touch Supabase at construction time** (asserted by `test/app/providers_test.dart`).
- **Every controller extends `BaseController`** (`lib/core/state/base_controller.dart`, a `ChangeNotifier`). Use `runAction` for writes, `runQuery` for reads, `watchTable` for realtime. These **never throw** — failures land in `status`/`error`, rendered via `describeError` from `lib/core/error/describe_error.dart`.
- **Only the events feature is fully layered** (`domain/` + `data/` + `presentation/`). The other features (`auth`, `chats`, `circles`, `friends`, `invitations`, `profile`) currently hold just a controller in `presentation/`, ported from the old MVC layout; they still query Supabase directly and should be migrated to the events shape when their UI is wired.
- **The provider scope is a `ChangeNotifierProxyProvider<AuthController, ProfileController>` for the session.** `ProfileController.syncSession` follows `AuthController.userId`: it loads the profile on a sign-in and clears it on a sign-out. It queues the work in a microtask because the proxy `update` runs during a build.
- **`AuthController` owns the Supabase session** (`features/auth/presentation/auth_controller.dart`). `initialize()` is what restores the persisted session and starts following auth changes; it is called once by `AuthGate`, deferred to a post-frame callback because it notifies synchronously. Never touch Supabase in a constructor.
- **`AuthGate` (`lib/features/auth/presentation/auth_gate.dart`) is `home:`** and decides between splash → login → password recovery → onboarding → `NavBarShell`. Auth screens are pushed from `LoginPage` with `MaterialPageRoute`s, not named routes.
- Onboarding is 3 steps in `lib/features/onboarding/presentation/onboarding_flow.dart`; it writes `profiles.onboarding_completed`. A `profiles` row is created by the `on_auth_user_created` trigger at sign-up, so the client only updates it.
- `AUTH_REDIRECT_URL` (default `app.gathermap://login-callback`, in `auth_controller.dart`) must match the Android intent-filter, the iOS `CFBundleURLTypes` scheme, and the Supabase redirect list. Setup steps are in the README.
- **Generated row types stay behind the data layer in the layered features.** `features/events/data/event_mapper.dart` is the single bridge to `lib/models/event.dart`; a schema regen can only ripple through the mapper. The unmigrated controllers (including `ProfileController`) still import `lib/models/` directly.
- Row access uses extension getters on the client (`client.event`, `client.profile`, …) from `lib/models/supadart_header.dart`. Data sources and unmigrated controllers import that header explicitly.
- UI shell: `lib/app/shell/nav_bar_shell.dart` hosts the four tabs in an `IndexedStack` and builds each tab only once visited (starting MapLibre on launch would ANR). Detail routes in `AppRoutes.hiddenNavRoutes` hide the bottom bar through `CurrentRoute`; `AppRoutes.onGenerateRoute` lives in `lib/core/routing/app_routes.dart`.
- The Events and Messages tabs still render hard-coded placeholder models (`EventItem`, `ChatItem`); only the map and the create-event dialog are wired to a real controller.
- **Device location lives in `lib/services/location_service.dart`** (cross-feature glue, alongside `data/supabase/`): a `LocationProvider` seam over `geolocator` (hand-written fakes in tests) plus a `LocationService.locate()` that never throws and folds denials into a `LocationResult`. The locate button in `features/map/presentation/widgets/map_widget.dart` takes an injectable `LocationService`. Android declares `ACCESS_FINE/COARSE_LOCATION`, iOS declares `NSLocationWhenInUseUsageDescription`; the browser prompts on its own (web needs HTTPS/localhost).

## Generated code & Supabase

- `lib/models/*.dart` are generated by the **Supadart** CLI from the linked project schema (files carry a "auto-generated by Supadart" header); config is `supadart.yaml`. **Do not hand-edit them** — regenerate with `supadart` (needs `SUPABASE_URL` + a _secret_ `SUPABASE_API_KEY`). `supadart.yaml` maps `profiles: Profile`, which is what makes the accessor `client.profile`.
- The README "Dart type generation" section was rewritten to match this; the old `tool/gen_types.sh` / `.githooks` instructions referred to files that do not exist in this repo.
- `supabase/` is gitignored **except `supabase/migrations/`** (see `.gitignore`), so schema changes must land as a migration there. The linked project config (`config.toml`, `.temp/`) stays local. There is no `supabase/seed.sql` despite the README's `db dump` example.
- Schema/RLS lives in `supabase/migrations/20261019090000_profiles_and_rls.sql`: `public.profiles` (keyed to `auth.users`), the `on_auth_user_created` trigger, helper functions used by the policies, and RLS for every table. It opens with a destructive dev reset (drops `public."user"`).
- Keep `supabase_flutter` and `postgrest` pinned to the `3.0.0-dev.9` prereleases in `pubspec.yaml`; the generated model output depends on them.

## Testing quirks

- Controller tests use hand-written fakes; no mockito/mocktail, no live DB. `EventController` tests pass a `_FakeEventRepository` implementing the domain interface, so they never touch Supabase.
- Feed state directly where a setter is marked `@visibleForTesting`.
- Widget tests that mount the app must stub the map plugin by replacing `MapLibrePlatform.createInstance` with a fake `MapLibreMethodChannel` (see `test/widget_test.dart`); otherwise disposal throws `LateInitializationError`.
- Widget tests host `NavBarShell` on `buildProviderScope` + `MaterialApp` rather than pumping `MyApp` (which goes through `AuthGate` and would need a session). See `test/widget_test.dart`.
- Auth state in widget tests is faked with the `@visibleForTesting` seams: `AuthController.setSessionForTest(session)` and `ProfileController.setCurrent(profile)`. `setSessionForTest` also marks the controller initialized, so `AuthGate`'s deferred `initialize()` never reaches for `Supabase.instance`. `test/features/auth/presentation/auth_gate_test.dart` also has one test that skips the seam (`authController(..., initialize: false)`) to exercise the gate's own restore, which is where notifying during build would surface. See `test/support/auth_harness.dart`.
- Auth requests are tested for real by `test/support/auth_harness.dart`: `authController(handler)` builds a `SupabaseClient` on a `MockClient` (in-memory PKCE/session storage, no refresh timer) and initializes it like `AuthGate` does. Use it for sign-up/sign-in/resend flows and for the login screen's confirmation notice — no network involved.
- GoTrue failures reach the app **without their error code**: `supabase_auth` keeps an error code only when the response's `code` field is a string, while GoTrue puts the HTTP status there and the identifier in `error_code`. `authErrorMessage` therefore matches identifiers first and GoTrue's wording second; keep both in step when adding a message. `AuthController` detects the unconfirmed-address refusal the same way.
- `pumpAndSettle()` never quiesces on the Map tab (`LoadingDots` animates forever under the fake platform) nor on `SplashScreen` — use bounded `pump(...)` there.
- `CreateEventDialog` takes an optional `AddressSearch`, so the geocoder can be stubbed instead of hitting MapTiler.

## Conventions

- `STYLE_GUIDE.md` governs naming (files `snake_case`, classes `PascalCase`, members `camelCase`) and git: commits `Feat-(Description)` / `Fix-(Description)` / `Doc-(Description)`; branches `create-` / `update-` / `patch-`.
- Lints come from `flutter_lints` via `analysis_options.yaml`; `build/` and platform dirs (`android/`, `ios/`, `web/`, …) are excluded from analysis.
- `lib/core/logging/logs.dart` wraps `package:logging`; `lib/core/theme/` exposes colors/text styles as `ThemeExtension`s read through the `context.colors` / `context.textStyles` getters.
- Shared presentation widgets (`SectionTitle`, `Avatar`, `AvatarRow`, `PageHeader`, `LoadingDots`, `AppPrimaryButton`/`AppSecondaryButton`/`AppErrorText`, `AppTextField`, `SplashScreen`) live in `lib/core/widgets/`; feature-specific ones stay under `features/<name>/presentation/widgets/`.
