<!--
Sync Impact Report
- Version: template → 1.0.0 (initial ratification)
- Principles added: I–V (all new)
- Sections added: Technical Constraints, Development Workflow, Governance
- Templates: plan-template.md derives its Constitution Check gates from this file (✅ no edit needed);
  spec-template.md / tasks-template.md (✅ no principle-specific references)
- Deferred: none
-->

# GatherMap Constitution

GatherMap is a Flutter app (Dart SDK `^3.11.4`, Flutter stable) backed by Supabase. Runtime
guidance for agents lives in `AGENTS.md`; naming and git rules live in `STYLE_GUIDE.md`. This
constitution states the rules that every spec, plan and task must respect.

## Core Principles

### I. Feature-First Clean Architecture

Code is organised by feature under `lib/features/<name>/`, each feature split into `data/`,
`domain/` and `presentation/`. Dependencies MUST only point inward: `presentation → domain ← data`.

| Layer | May import | Must not import |
|-------|-----------|-----------------|
| `domain/` | other `domain/` files | Flutter, Supabase, `lib/models/` |
| `data/` | `domain/`, `core/`, `data/`, `lib/models/` | `presentation/` |
| `presentation/` | `domain/`, `core/`, Flutter | Supabase, `data/` |

- Controllers reach I/O only through repository interfaces declared in `domain/`.
- Concrete implementations are chosen in exactly one place: `lib/core/di/providers.dart`.
- Cross-feature code goes in `lib/core/`, which MUST NOT import any feature.
- New or reworked features MUST follow the fully layered `events` feature. The unmigrated
  controllers (`auth`, `chats`, `circles`, `friends`, `invitations`, `profile`) MUST be migrated
  to this shape when their UI is wired. Don't add new direct-Supabase controllers.

*Rationale:* a schema change or backend swap should only ripple through `data/`.

### II. Generated Code Is Untouchable

- `lib/models/*.dart` is Supadart output. It MUST NOT be hand-edited and is regenerated with
  `supadart` (config: `supadart.yaml`).
- In layered features, generated row types MUST stop at the feature's mapper in `data/`
  (e.g. `features/events/data/event_mapper.dart`). Domain entities are plain Dart.

*Rationale:* a regen should not overwrite hand edits, and should only touch mappers.

### III. Controllers Never Throw

- Every controller MUST extend `BaseController` (`lib/core/state/base_controller.dart`).
- Writes use `runAction`, reads use `runQuery`, realtime uses `watchTable`. Failures land in
  `status`/`error` and are rendered through `describeError`
  (`lib/core/error/describe_error.dart`), never as uncaught exceptions.

*Rationale:* the UI has one predictable way to show loading and error states.

### IV. No I/O at Construction Time

- Building the provider graph (`AppDependencies`, `buildProviderScope()`) MUST NOT touch
  Supabase or perform any I/O; `SupabaseService` resolves its client on first query.
- Constructors MUST NOT reach for `Supabase.instance`. Session restore happens in
  `AuthController.initialize()`, called once from `AuthGate` in a post-frame callback.
- Heavy native views (e.g. MapLibre) MUST be built lazily. `NavBarShell` builds a tab only once
  it's visited.

*Rationale:* this keeps startup fast (no ANR) and makes the graph testable without a backend.
`test/app/providers_test.dart` asserts it.

### V. Tests Never Touch the Network

- Tests use hand-written fakes that implement domain interfaces. No mockito/mocktail, no live
  database, no `.env`.
- Auth flows are tested through `test/support/auth_harness.dart` (a real `SupabaseClient` on a
  `MockClient`). Geocoding is stubbed through the injectable `AddressSearch`, and location
  through the `LocationProvider` seam.
- Widget tests that mount the map MUST stub `MapLibrePlatform.createInstance`, and MUST use bounded
  `pump(...)` where `pumpAndSettle()` never quiesces (Map tab, `SplashScreen`).
- Every feature ships with tests for its controller and domain rules. `flutter analyze` MUST be
  clean and `flutter test` MUST pass. These are the CI gates.

*Rationale:* the suite has to be deterministic and run anywhere, including CI.

## Technical Constraints

- **Backend:** Supabase. Schema and RLS changes MUST land as a new file in
  `supabase/migrations/` (the rest of `supabase/` stays local). Every table has RLS. A
  `profiles` row is created by the `on_auth_user_created` trigger, so clients only update it.
- **Pinned deps:** `supabase_flutter` and `postgrest` stay on the `3.0.0-dev.9` prereleases,
  because the generated models depend on them.
- **Config:** compile-time only, via `String.fromEnvironment` and `--dart-define-from-file=.env`.
  Secrets MUST NOT be committed.
- **Auth redirect:** `AUTH_REDIRECT_URL` (`app.gathermap://login-callback`) MUST stay in sync
  across the Android intent-filter, iOS `CFBundleURLTypes`, and the Supabase redirect list.
- **UI:** colors and text styles come from the theme extensions (`context.colors`,
  `context.textStyles`). Shared widgets go in `lib/core/widgets/`; feature-specific widgets stay
  in the feature's `presentation/widgets/`.
- **Logging:** use `lib/core/logging/logs.dart`, not `print`.

## Development Workflow

- **Naming:** files and paths are `snake_case`, classes `PascalCase`, members `camelCase`
  (`STYLE_GUIDE.md`).
- **Branches** are created by hand with the STYLE_GUIDE prefixes `create-` / `update-` /
  `patch-`. Spec Kit's git extension is deliberately not installed. Specs still live in
  `specs/NNN-short-name/`, independent of the branch name.
- **Commits** use `Feat-(Description)`, `Fix-(Description)` or `Doc-(Description)`.
- **Spec flow:** `/speckit-specify` → (`/speckit-clarify`) → `/speckit-plan` → `/speckit-tasks` →
  (`/speckit-analyze`) → `/speckit-implement`. Plans MUST pass the Constitution Check before
  research, and again after design.
- **Definition of done:** `flutter analyze` is clean, `flutter test` is green, and `AGENTS.md`
  is updated when architecture or testing conventions change.

## Governance

This constitution overrides conflicting guidance in specs, plans and tasks. If it conflicts with
`AGENTS.md` or `STYLE_GUIDE.md`, all three are reconciled in the same change.

- Amendments go through `/speckit-constitution` and are versioned semantically. MAJOR means a
  principle is removed or redefined incompatibly, MINOR means a principle or section is added or
  materially expanded, and PATCH means a clarification or wording change.
- Any deviation MUST be justified in the plan's Complexity Tracking table, or the plan is
  rejected.
- Reviews check that changes follow Principles I–V.

**Version**: 1.0.0 | **Ratified**: 2026-11-20 | **Last Amended**: 2026-11-20
