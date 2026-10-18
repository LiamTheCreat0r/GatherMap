# Application Architecture Reference

Companion to `AGENTS.md`. Decision guidance for structuring a Flutter app's `lib/`.

## Layout vs Architecture (read this first)
These two terms are orthogonal and combine freely — don't confuse them:
- **Layout** is the *physical* folder structure: how `lib/` is organized on disk.
  This doc covers two layouts — `feature-first` and `layer-first`.
- **Architecture** is the *logical* separation of responsibilities and their
  dependency direction (e.g. MVVM, MVP, Clean). It decides what each piece owns
  and which way dependencies point.
- You pick a Layout (where files live) **and** an Architecture (who owns what);
  e.g. feature-first Layout + MVVM Architecture is a common, valid pairing.

## Layout: feature-first (recommended for non-trivial apps)
```
lib/
  core/            # cross-cutting: constants, theme, router, di, utils
  shared/          # cross-feature reusable widgets/components, theme tokens, base UI
                  # (alternative names: common/, components/, ui/ — follow the repo)
  features/
    auth/
      auth.dart    # BARREL: re-exports data/domain/presentation so callers import one file
      data/        # models, repositories, data sources (api, local)
      domain/      # entities, use cases, repository interfaces
      presentation/# pages, widgets
        view_model/# MVVM: AuthViewModel (state + commands, framework-agnostic)
        widgets/   # feature-local reusable widgets (promote to shared/ if cross-feature)
        # MVP alternative: presenter/ instead of view_model/
        # State container (bloc/riverpod/cubit) also lives here if used
    profile/
      ...
  main.dart
```
- Keeps a feature's code colocated; scales better than layer-first.
- Use a **barrel file** at the feature root (`auth.dart` re-exporting its
  subfolders, or an `index.dart` inside each subfolder) so other code imports one
  path instead of deep relative imports. The barrel is **not MVVM-specific** —
  it applies to any architecture.
- Put genuinely cross-feature reusable widgets (buttons, cards, inputs, headers,
  shared empty/error states, list rows) in `shared/` so features compose them
  instead of duplicating markup. Promote a `presentation/widgets/` widget to
  `shared/` only once it is used by two or more features. See the
  *Componentization & reuse* section in `AGENTS.md`.
- `domain` depends on nothing but itself; `data` implements `domain` interfaces; `presentation` calls `domain`.

## Layout: layer-first (fine for small apps)
```
lib/
  data/ domain/ presentation/ (or ui/) core/
```
Simpler to reason about at the start; refactor to feature-first as it grows.

## Pattern detection first (read before choosing)
Before imposing any architecture, **detect what the project already uses**:
- Scan `lib/` for existing layers (`data/` `domain/` `presentation/`), state
  packages (`flutter_bloc`, `riverpod`, `provider`, `mobx`, `get` / `get_it`),
  and naming (`*_view_model.dart`, `*_controller.dart`, `*_presenter.dart`,
  `*_bloc.dart`).
- If a clear pattern is already present, **follow it** — do not rewrite to a
  different pattern. Document the detected choice in the README if absent.
- Only when no pattern is detectable (greenfield or mixed/undecided) do you
  recommend a default, per the ranking below.

## Architecture pattern ranking (when no choice exists)
Default recommendation order when the project has no established pattern:

1. **MVVM** (Model–View–ViewModel) — **default recommendation.**
   - Separation: `View` (widgets) ↔ `ViewModel` (state + commands, framework-agnostic)
     ↔ `Model` (domain + data). View observes the ViewModel; business logic lives
     in the ViewModel, not the widget.
   - Pairs cleanly with Riverpod/Provider/Bloc for the ViewModel's reactive state.
   - Best general fit for most Flutter apps: testable, scalable, familiar.
2. **MVP** (Model–View–Presenter) — fall back here when the team prefers explicit
   Presenters over reactive ViewModels, or the UI layer must stay passive/testable
   with manual binding (e.g. heavily widget-tested legacy code).
3. **Other** (Clean Architecture, Redux, MVC-lite, etc.) — only when project
   constraints explicitly demand it (strict layering, shared cross-platform core,
   existing team standard). Prefer the lightest pattern that meets the need.

Rule: recommend the **highest** option on this list the project can adopt; do not
skip MVVM for MVP unless a concrete reason exists. Once a pattern is chosen, keep
it consistent across features and note it in the README.

## State management selection
- **Riverpod / Provider** — scoped DI + reactive state; low boilerplate; good default.
- **Bloc / Cubit** — event-driven, explicit states, great for complex flows and testability.
- **GetIt + injectable** — service-locator DI; pair with any state solution.
- Pick ONE primary approach per project; document it in the README.

## Rules of thumb
- UI (presentation) must not contain business logic; delegate to use cases / services.
- Dependencies point inward (presentation → domain → data); never the reverse.
- Models are immutable `final` classes; use `freezed`/`equatable` for value equality.
- Keep `lib/` importable as a unit; do not reach into another package's `lib/src/`.

## Testing layering
- `domain` — pure unit tests (fast, no Flutter).
- `data` — unit tests with mocked sources; verify mapping & error handling.
- `presentation` — widget tests for critical flows; integration tests for end-to-end.
