---
name: flutter-agent-skills
description: This skill provides general Flutter/Dart development guidance - implementing features, fixing bugs, managing pubspec dependencies and version constraints, following effective_dart, structuring lib/ (feature-first architecture, state management selection), writing platform channels for plugins across Android/iOS/Linux/macOS/Windows/Web/OpenHarmony, running flutter analyze/flutter test, and publishing to pub.dev. Use it for any Flutter or Dart project task.
version: 1.0.0
---

# Flutter Agent Skills

> **Self-contained bundle (v1.0.0).** This `SKILL.md` is an auto-generated, complete copy
> of the guidance from [`AGENTS.md`](https://github.com/zero-labsco/zero-skills/blob/main/skills/flutter-agent-skills/AGENTS.md) and the docs
> in `references/` (the canonical sources in this kit's repository root). It is
> bundled so the skill works on its own even when a marketplace (e.g. skills.sh)
> downloads only `SKILL.md`. The helper scripts (`scripts/`) are NOT included in
> this download — clone the repo at https://github.com/zero-labsco/zero-skills to run them.
>
> **Tool-agnostic.** This skill loads via `SKILL.md` in any agent that supports
> the format — Claude Code, Cursor, Codex, GitHub Copilot, CodeBuddy, OpenCode,
> Aider, and any other tool skills.sh or a compatible marketplace targets.
> Follow the guidance below for any Flutter / Dart task regardless of which tool
> you use.

## Overview
This skill activates for any Flutter / Dart project work. The guidance below is
the tool-agnostic, bundled core: architecture, coding conventions, dependency
and version rules, plugin platform-channel patterns, verification commands, and
the deep-dive reference appendices.

## General guidance (bundled from AGENTS.md)

## Scope
Applies to **any** Flutter / Dart project, covering two scenarios:
- **Application projects** — UI apps with `lib/`, state management, networking, persistence.
- **Plugin projects** — packages exposing a platform channel for Android/iOS (and beyond).

**In scope (this kit owns these):** general Flutter / Dart conventions, `lib/`
structure, architecture pattern selection, dependency and version rules,
platform-channel patterns, verification commands, and the anti-AI-smell /
anti-hallucination discipline. These are tool-agnostic and apply to every project.

**Out of scope (this kit does NOT own these):** project-specific decisions and
facts — exact package names and versions, business/domain logic, directory depth
and folder naming beyond the recommended layouts, CI/CD configs, secrets, and any
rule that is unique to one repo. Those belong in the **project's own `AGENTS.md`**
(or its team docs), which should override this kit when they conflict. When a
project already has an established convention, follow it (see *Match the existing
codebase, not a template*) and do not impose this kit's defaults.

## Uncertainty handling (say so instead of guessing)
When you are **not certain** about a fact — an API's existence or signature, a
package's export, the project's intended behavior, a version's compatibility — do
**not** fabricate a plausible-looking answer. Instead:
- **State the uncertainty explicitly.** Say "I can't verify X from the available
  context" rather than emitting a confident-but-unchecked symbol or snippet.
- **Point to where to verify.** Name the source to check: `dart doc`, the package
  source in `pubspec.lock`, `pub.dev`, the project's own code/docs, or
  `flutter analyze` to surface errors. See *API truthfulness*.
- **Prefer a safe, minimal stub over a wrong implementation.** If you must
  proceed, write the smallest correct shape you can defend and flag what needs
  confirmation, instead of guessing parameters or methods.
- **Ask when the cost of being wrong is high** (data loss, breaking changes,
  auth/security). A short clarifying question beats a silent wrong assumption.

## Coding conventions
- Follow `effective_dart`. Enforce with `flutter analyze` and `flutter_lints`.
- Use null safety; avoid `!` unless proven safe. Prefer `final` and immutable models.
- Name files `snake_case.dart`, classes `PascalCase`, constants `lowerCamelCase` or `kConstant`.
- Keep `lib/` free of business logic leakage into UI; separate data / domain / presentation.
- Do not write hardcoded secrets; use `--dart-define` or a `.env` excluded from VCS.
- Do not **hardcode theme values**. Do **not** create a color-constants file
  (e.g. `app_colors.dart` with `static const brand = Color(0xFF2E5BFF)`) — that
  only relocates hardcoded colors and still can't adapt to light/dark or brand
  swaps. Instead:
  - Define the palette **once** in the app's `ThemeData`, derived from a single
    seed color via `ColorScheme.fromSeed(seedColor: ...)`. Let Flutter generate
    the shades (primary, surface, error, …) for you.
  - In widgets, read everything from the theme at runtime — `Theme.of(context)
    .colorScheme.primary`, `.textTheme.titleLarge`, `.colorScheme.error` — never
    literal `Color(0xFF...)`, `Colors.x`, or magic pixel numbers inline.
  - The only acceptable exception is a project that already ships its own
    design-token system wired into the theme (light/dark aware); then import those
    tokens, don't invent new hardcoded ones. This keeps the look consistent and
    themeable. See the UI guidance.

## Dependencies and versioning
- Prefer the caret (`^`) constraint on pub dependencies; do not pin exact versions without reason.
- Keep `sdk` constraints realistic (e.g. `>=3.0.0 <4.0.0`); do not over-constrain.
- Run `flutter pub upgrade` and commit `pubspec.lock` for applications; plugins should commit it too.
- Before publishing: `flutter pub publish --dry-run` to catch missing files and score `pana`.

## Architecture (application)
- Use a **feature-first** layout: `lib/features/<feature>/{data,domain,presentation}/`.
- Or a **layer-first** layout for small apps: `lib/data/`, `lib/domain/`, `lib/presentation/`.
- Choose state management deliberately: `Provider`/`Riverpod` for scoped DI, `Bloc`/`Cubit` for event-driven flows, `GetIt` for service locators. Document the choice in the project README.
- **Default when unchosen:** if the project has no established state-management
  approach, recommend **Riverpod** (or `Provider` for very small apps) as the
  default — low boilerplate, scoped DI, and strong testability. Only pick
  `Bloc`/`Cubit` when the flow is genuinely event-driven and benefits from
  explicit states. Pick ONE primary approach and document it.
- Never import `lib/src/` of a dependency directly; use its public API only.
- **Read existing code before generating.** Imitate the project's established
  patterns (file layout, naming, error handling, state shape) rather than emitting
  a generic template. Code that looks identical across every project is the
  tell-tale sign of an LLM — match the repo's voice.
- **Verify APIs before using them** (see *API truthfulness*). Never assume a
  method/constructor/parameter or package export exists — confirm it in the
  pinned SDK/package version.

## Componentization & reuse (reduce duplication)
Prefer **composable, reusable components** over copy-pasted UI and logic. Aim to
remove duplication wherever the same markup or behavior appears more than once:
- **Extract before repeating.** The first time you write a block of UI, leave it
  inline. The **second** time the same structure appears, extract it into a
  named widget / helper / function. Three or more repetitions of near-identical
  code is a strong signal to refactor into a shared component.
- **Build a small shared component set.** Colocate genuinely reusable widgets
  (buttons, cards, inputs, headers, empty/error states, list rows) in
  `lib/<feature>/presentation/widgets/` or a cross-feature `lib/shared/`
  (or `lib/common/`, `lib/components/`) following the project's existing
  convention. Give them clear, single-purpose names — not `MyWidget`.
- **Parameterize, don't fork.** When two usages differ only by data, color, or
  callback, pass them as parameters instead of duplicating the widget with
  hardcoded variants. Prefer `const` constructors and a small set of named
  arguments over long positional lists.
- **Prefer composition over inheritance.** Compose small widgets (a `Card` +
  `ListTile` + `Icon`) rather than subclassing to reuse a look. Flutter widgets
  are cheap to nest; levers like `Builder`, `LayoutBuilder`, and `InheritedWidget`
  / provider reads share behavior without copying code.
- **Reuse logic, not just markup.** Lift repeated business rules, formatting,
  validation, and parsing into services / extensions / free functions in
  `domain` or `core/utils`; don't re-implement the same `if` chain in three
  screens. Share state via the chosen state-management container instead of
  duplicating fetches.
- **Match the project's existing components first.** Before adding a new shared
  widget, check whether one already exists (search `lib/shared`, `lib/common`,
  existing `*_widget.dart`). Reuse the repo's own building blocks so the UI stays
  consistent — do not introduce a second, parallel component library.
- **Keep components self-contained and dependency-light.** A shared widget should
  not reach into a specific feature's state or data layer; pass what it needs via
  the constructor. That keeps it reusable and avoids accidental coupling.
- **Don't over-abstract.** Extract a component only when it earns its place (two+
  real call sites, or a genuinely shared cross-feature need). A one-off widget
  pulled into `shared/` prematurely adds indirection with no payoff.

## Navigation & routing (avoid inline routes)
- **Don't inline `Navigator.push(MaterialPageRoute(...))` blocks** inside widgets.
  That scatters destinations and the page-construction logic across the codebase.
- **Use a centralized router** when the project has one — `go_router`,
  `auto_route`, or the project's own `RouteGenerator`. If the project has no
  convention, recommend `go_router` (declarative, typed routes, deep-linking) as
  the default for new apps.
- **Keep routes in one module, not scattered.** Define the router in a dedicated
  location rather than inside `main.dart` or individual pages:
  - Small apps: a single `lib/router.dart` (or `lib/app_router.dart`) holding the
    `GoRouter`/`RouterConfig` instance.
  - Larger / multi-feature apps: a `lib/router/` (or `lib/routing/`) folder with
    the router, route table, and guards split out (e.g. `app_router.dart`,
    `routes.dart`, `guards.dart`).
- **Define path strings as constants.** Don't write magic route strings like
  `context.go('/users/123')` across widgets — centralize them (e.g.
  `route_paths.dart` with `static const users = '/users';` and a typed
  `usersDetail(String id)` helper) so destinations have one source of truth.
- **Pass typed arguments, not raw Maps/strings.** Route params should be typed
  (e.g. `GoRouterState.pathParameters['id']` parsed to the real type), not a
  loosely-typed `Map<String, dynamic>` passed through constructors.
- **Match the project's existing navigation** before introducing a new approach.
  If screens currently use named routes or a specific package, stay consistent.

## Architecture (plugin)
- Define the abstract API once in `lib/<pkg>_platform_interface.dart` (`<Pkg>Platform`).
- Provide a concrete impl per target platform: `MethodChannel` for Android / iOS / macOS / Linux / Windows / OpenHarmony (鸿蒙), and pure-Dart `dart:js_interop` for Web (no MethodChannel).
- Register the right impl conditionally (use `kIsWeb` + `dart:io` `Platform.isX`) in the public barrel; re-export public symbols only. Consumers call the abstract API and never change when a platform is added.
- Keep native changes minimal and matching the method-channel contract. Android lives under `android/src/main/kotlin/...`, iOS/macOS under `ios/Classes` / `macos/Classes`, Linux/Windows under `linux/` / `windows/` (C++), OHOS under `ohos/` (ArkTS).
- See the **Plugin Platform Channel Reference** appendix below for a full multi-platform template.

## Testing discipline
Generated code should be **accompanied by tests**, not shipped alone:
- **Write a test for every non-trivial change.** A new use case, repository
  method, formatter, or validation rule gets a unit test. A new screen or flow
  gets at least one widget/integration test covering the critical path.
- **Test by layer** (see *Testing layering* in the Architecture Reference):
  `domain` as pure unit tests; `data` with mocked sources (verify mapping and
  error handling); `presentation` with widget tests for key flows and
  integration tests for end-to-end.
- **Make it runnable and green.** After generating, the project must pass
  `flutter analyze` and `flutter test` (or `dart analyze` / `dart test` for
  non-Flutter packages). Do not leave failing or commented-out tests behind.
- **Prefer meaningful assertions** over "does not throw". Assert behavior and
  state, not just that the code executed.
- **Match the project's existing test style** (test framework, mocking library,
  file location `test/` vs `*/test/`) before introducing a new pattern.

## Dependency discipline
Adding a package is a decision, not a reflex:
- **Confirm the need first.** Before adding a dependency, check whether the SDK
  or an existing package already covers the use case (e.g. `dart:convert`,
  `dart:async`, `flutter/material.dart`). Prefer the standard library over a
  third-party package.
- **Audit the package before adding.** On `pub.dev`, check the **popularity +
  health + maintenance** scores, last published date, open issues, and null-safety
  / SDK compatibility. Avoid unmaintained or single-maintainer packages for
  critical functionality.
- **Avoid overlapping packages.** Don't add two packages that do the same thing
  (e.g. multiple HTTP clients, multiple state libraries). One chosen approach per
  concern.
- **Scope correctly.** Runtime needs go in `dependencies`; test/build tooling
  goes in `dev_dependencies`. Never commit a permanent `dependency_overrides`.
- **Pin with care** (see *Dependencies and versioning*): prefer caret (`^`)
  constraints; don't pin exact versions without reason.

## Error handling (fail loudly, recover gracefully)
Generated code should treat failures as first-class, not an afterthought:
- **Don't swallow exceptions.** Avoid bare `catch (e) {}` or `try { … } catch (_)`
  that discards the error. At minimum log it; rethrow or surface it when the
  caller can act on it.
- **Represent failure explicitly.** For operations that can fail, prefer throwing
  a typed exception or returning a `Result`/sealed type over returning `null` to
  mean "it broke". A `null` success/failure ambiguity is a common source of
  downstream crashes.
- **Use `async`/`await` + `try`/`catch`** for async work rather than nested
  `.then().catchError()` chains, which are harder to read and easy to leave
  unhandled.
- **Show the user a recoverable message, not a stack trace.** Map errors to a
  human-readable, localized string (see *Internationalization*) and offer a retry
  where it makes sense — using the project's existing error/empty-state pattern,
  not a generic dialog.
- **Catch at the right boundary.** Let lower layers (`data`/`domain`) throw and
  let the presentation layer decide how to present the failure, rather than
  catching and hiding it deep inside a repository.

## Internationalization (i18n)
- **Don't hardcode user-facing strings.** Extract them to `arb` files
  (`lib/l10n/app_en.arb`, `app_zh.arb`, …) via `flutter_localizations` +
  `intl` (or `slang`/`easy_localization` if the project already uses one).
- **Generate the delegate** (`flutter gen-l10n`) and wire `localizationsDelegates`
  + `supportedLocales` in `MaterialApp`/`CupertinoApp`. Follow the project's
  chosen i18n tool, not a new one.
- **Keep plurals/formatting in the arb**, not in Dart string concatenation, so
  translators and locale rules are respected.
- **Never convey meaning by UI text alone** for accessibility — pair labels with
  icons/semantics as noted in the UI guidance.

## Verification commands (run locally before pushing)
- `dart format --line-length 80 .` (or `flutter format`) — must report no
  unformatted files. Run formatting before analyze; never hand-format around the
  formatter.
- `flutter analyze` — must pass with no errors.
- `flutter test` — all unit tests green.
- `flutter pub publish --dry-run` — confirm `pana` score and no excluded files.

## Helper scripts
Located in `scripts/dart/` (Dart, cross-platform, runs on the Dart SDK every Flutter
dev already has) and `scripts/python/` (Python, for environments without the Dart
SDK). Both implement the same behavior and CLI; pick whichever fits your environment.

Run Dart with `dart run scripts/dart/<name>.dart [args]`, or Python with
`python scripts/python/<name>.py [args]` (or `python3`).

- `verify` — runs format + analyze + test + publish dry-run. `[--no-publish]` skips the publish check.
- `create_feature <name>` — scaffolds a feature-first folder (`lib/features/<name>/{data,domain,presentation}/`).
- `bump_version <major|minor|patch>` — bumps a **target Flutter project's**
  `pubspec.yaml` (the source of truth for that project's version) and prints the
  git tag command. It does not touch this kit's repo-root `VERSION` file — that
  file is unrelated kit metadata, not a Flutter version.
- `build_skill` — regenerates the self-contained `SKILL.md` bundle from this `AGENTS.md` (run after editing guidance).

## UI & visual design (avoid the "AI-generated" look)
Generated UIs are easy to spot and easy to dislike. Prefer craft over defaults:
- **No tell-tale AI clichés.** Avoid the default purple→blue gradient, the
  ubiquitous glassmorphism / blurred cards, gratuitous glows and shadows, the
  rounded-everything "bubble" aesthetic, and decorative emoji used as icons
  (🔥 ⚡ 🚀) where a real icon or type should go.
- **Real typographic hierarchy.** Use a deliberate type scale (e.g. 32/24/16/14),
  weight and color for contrast — not size alone. Left-align text in LTR unless a
  deliberate centered hero is justified.
- **Restrained, intentional color.** Pick a small palette (one brand color + a
  neutral ramp), keep saturation modest, and reserve accent color for a single
  primary action. Don't color every card differently.
- **Meaningful spacing.** Use a consistent spacing scale (4/8/16/24/32) instead
  of arbitrary margins; let whitespace group, not lines/borders.
- **Follow the platform.** Match Material 3 or Cupertino conventions for the
  target OS; don't force one platform's idiom onto the other. Respect safe areas
  and system fonts.
- **Accessibility is baseline.** Hit targets ≥ 48px, AA contrast (4.5:1 text),
  don't convey meaning by color alone, and support dynamic type / large fonts.
- **Motion with purpose.** Animate state changes and transitions; avoid
  decorative loops. Keep durations ≤ 300ms and respect reduced-motion settings.
- **Match the existing codebase, not a template.** Before generating UI, read the
  project's existing screens/widgets and imitate *their* spacing, typography,
  color usage, and component choices. Never impose a uniform "default" look
  (e.g. one shared gradient background, identical `Card` styling, the same
  `ListTile` everywhere) just because it's convenient — that uniformity is the
  single biggest tell of AI-generated code.
- **No gratuitous state scaffolding.** Don't wrap every screen in loading /
  error / empty-state widgets by default. Add them only where the data is
  genuinely async or can be empty; when present, use the project's existing
  pattern rather than a generic spinner/skeleton.
- **Avoid boilerplate decoration.** Don't add shadows, borders, rounded corners,
  dividers, or icons that don't earn their place. Prefer the platform's built-in
  widgets (`ListTile`, `AppBar`, `FilledButton`) over hand-rolled look-alikes.
- **Don't invent copy or content.** Use the labels/strings the project already
  uses; don't sprinkle placeholder marketing text or emoji. If a label is
  missing, ask or use a minimal neutral placeholder — never fabricate tone.

## API truthfulness (never hallucinate an API)
A leading source of broken Flutter code is the model "remembering" an API that
does not exist. Treat every method, constructor, parameter, class, and package
name as a claim that must be verified, never assumed:
- **Verify before you call.** Before using any SDK or dependency symbol, confirm
  it actually exists in the pinned version. Check `dart doc`, the package source,
  or `pub.dev` — do not trust recollection. If you cannot verify it, say so
  instead of guessing.
- **Match the installed version.** APIs differ across SDK/package versions
  (e.g. `Color.withOpacity` vs `withValues`, null-safety and `withNullSafety`
  changes, renamed exports). Read the version that is actually in `pubspec.lock`,
  not the one you vaguely recall.
- **Don't invent packages or exports.** Never assume a package exposes a symbol;
  import only what its public API documents. Don't fabricate import paths or
  `lib/src/` internals.
- **Prefer real signatures over plausible ones.** If you're unsure of a method's
  parameters or return type, look it up. A confident-but-wrong signature is worse
  than a flagged uncertainty.
- **Let the analyzer catch hallucinations.** After generating, run
  `flutter analyze` (or `dart analyze`); unresolved symbols, missing imports, and
  wrong signatures surface immediately. Treat analyze errors as proof you assumed
  an API — fix by verifying, not by papering over.

## Performance & memory
- **Build only what's needed.** Extract widgets so `build()` stays cheap; use
  `const` constructors and `ListView.builder` for dynamic lists. Avoid rebuilding
  heavy subtrees on every frame.
- **Mind the frame budget.** Keep UI work under 16ms (60fps) / 8ms (120fps);
  move heavy compute off the UI isolate (`compute`, isolates) and debounce
  rapid input.
- **Watch memory.** Dispose `TextEditingController`, `ScrollController`,
  `AnimationController`, `StreamSubscription`, and focus nodes in `dispose()`;
  avoid retaining large objects in closures; prefer paging over loading entire
  lists.
- **Images & assets.** Size/cache appropriately (`cached_network_image`), avoid
  full-resolution images in thumbnails, and use `AssetImage`/`exact` where known.
- **Avoid leaks in state.** Don't store `BuildContext` across async gaps or
  register listeners you never remove; close streams and providers when unused.
- **Profile, don't guess.** Use the DevTools performance and memory views before
  optimizing; measure on a mid-range device, not just the simulator.

## Async, concurrency & streams
Flutter apps are async by default; treat concurrency as a first-class concern, not
an afterthought bolted on with `.then()`:
- **Prefer `async`/`await` over `.then().catchError()` chains.** Linear `await`
  reads top-to-bottom and makes error flow obvious. Reserve `.then` for the rare
  fire-and-forget where you intentionally don't await.
- **Never block the UI isolate.** `await` on the network/disk is fine — that's
  cooperative, not blocking. What you must NOT do is run heavy synchronous compute
  (parsing, crypto, image processing) on the UI isolate. Offload to `compute()`
  or a dedicated `Isolate` and return a typed result.
- **Guard `BuildContext` across awaits.** After any `await`, check
  `if (!mounted) return;` before touching `context`/`setState` in a `StatefulWidget`.
  This is the #1 source of "setState after dispose" crashes. For other objects,
  don't retain a `BuildContext` in a closure or field across an async gap.
- **Cancel what you start.** Every `StreamSubscription`, `Timer`, and animation
  controller created in a widget or service must be cancelled/closed in
  `dispose()` (or a `cancel()` you call). A leaked subscription keeps firing into
  a dead widget.
- **Use `Stream`/`StreamController` deliberately, not by reflex.** Prefer
  `Future` for a single result and a typed `Stream<T>` (or a state container's
  async value) for a sequence. Don't expose a `StreamController` directly —
  expose its `.stream` and keep the `sink`/`add` private so callers can't inject
  events. Close the controller when the producer is done.
- **Don't conflate `FutureBuilder` with state management.** `FutureBuilder` is for
  a one-shot snapshot; it rebuilds and re-fetches when its parent rebuilds unless
  the `future:` is hoisted to a field. For data that lives across the widget tree,
  put it in the chosen state container, not a `FutureBuilder` in every screen.
- **Bound concurrency.** When fanning out many async tasks (parallel downloads,
  batch API calls), use a `Stream.asyncMap` with `concurrency` or a small
  pool rather than firing unbounded `Future.wait` that can exhaust sockets/memory.
- **Match the project's existing async style** (zones, `Either`/`Result` returns,
  a specific `dio`/`http` wrapper) before introducing a new pattern.

## Assets & resources
Assets are easy to get wrong silently (missing declarations, wrong paths, huge
bundles). Generated code should handle them deliberately:
- **Declare every asset in `pubspec.yaml`.** A file in `assets/` is NOT bundled
  unless it's listed under `flutter: assets:` (or its parent directory). The
  analyzer won't catch this — it fails at runtime.
- **Reference assets by constant, not literal strings.** Define path constants
  (e.g. `AssetPaths.logo = 'assets/images/logo.png'`) so a typo is a compile-time
  miss, not a runtime `Unable to load asset`.
- **Respect resolution-aware assets.** Use the `images/2.0x/`, `images/3.0x/`
  convention (or `AssetImage` + device pixel ratio) instead of one fixed-size file
  stretched across densities.
- **Keep bundles lean.** Don't ship full-resolution photos as thumbnails; prefer
  `cached_network_image` for remote images and correctly sized local assets.
  Large uncompressed assets bloat the install and slow cold start.
- **Don't hardcode asset paths in widgets** scattered across the app — centralize
  them like route paths (see *Navigation & routing*) so renaming lives in one place.
- **Fonts and other asset types** (`.ttf`, `.json`, `.arb`) follow the same
  declare-or-it-won't-ship rule; verify a new asset appears in the build, not just
  the folder.

## State management (use it, don't drown in it)
Picking a state container is necessary; over-engineering it is the common AI tell:
- **Pick ONE primary approach** (see *Architecture (application)*) and use it
  consistently — don't mix `Provider` reads, a `Riverpod` `Notifier`, and a
  global Bloc in the same screen.
- **Local before global.** If state is only needed by one widget subtree, keep it
  in that widget (`StatefulWidget` + `setState`, or a small local `StateNotifier`).
  Don't promote ephemeral UI state (a toggle, a text-field controller, an
  expand/collapse flag) to app-wide global state just because the tool makes it
  easy.
- **Model state as data, not as a bag of setters.** Define explicit state classes
  (immutable records/classes or a sealed `AsyncValue`/`Result`) with named fields
  and transitions, rather than a half-dozen loosely-typed `controller.updateX()`
  methods that any caller can desync.
- **Don't expose raw mutators everywhere.** Expose intent (actions/methods) and
  derived values (selectors), not a public mutable field that any widget can
  clobber. This keeps transitions valid and testable.
- **Keep state containers free of UI and I/O.** A `Notifier`/`Cubit`/ViewModel
  orchestrates; it shouldn't build widgets or open sockets directly. Push
  networking/persistence into the `data`/`domain` layer and inject it.
- **Make state testable in isolation.** A well-shaped container can be driven by
  calling actions and asserting resulting state without a `WidgetTester`. If you
  can't test it headless, the boundaries are wrong.
- **Match the project's existing state shape** (its `State` base class, loading
  wrapper, error envelope) before inventing a new one.

## JSON & serialization
Hand-rolled JSON parsing is where silent data corruption and `TypeError`s hide:
- **Prefer a codegen serializer over manual `fromJson`/`toJson` for non-trivial
  models.** `json_serializable` (or `freezed` + `json_serializable`) generates
  correct, exhaustive mapping and catches missing/renamed fields at build time
  via `build_runner` — far safer than hand-written maps that silently drop keys.
- **If you must hand-write `fromJson`, be defensive but honest.** Parse only the
  fields you expect, coerce types explicitly (`(json['id'] as int?)`, not
  `json['id']` cast blindly), and fail (throw a typed exception) on a malformed
  payload rather than returning a half-null object that crashes three screens
  later. See *Error handling*.
- **Never trust the wire type.** API responses drift; a field that was `int` can
  become `String`. Parse with `json['x'] as T?` and a sensible default or a clear
  error, not a bare `json['x'] as T` that throws on a `null` or mismatch.
- **Keep serialization at the edge.** `fromJson` belongs in the `data` layer
  (transforming the network DTO into your domain model). Domain models should not
  carry `Map<String, dynamic>` around — map once, then work with typed objects.
- **`DateTime`, `Uri`, enums** need explicit handling: pick a wire format
  (ISO-8601 strings), parse with `DateTime.parse`/`DateTime.tryParse`, and map
  enums via a lookup (not `Enum.values.byName` on an unknown string — guard it).
- **Don't round-trip through `toString()`.** Serialize structured fields to JSON
  properly; `obj.toString()` is not a wire format and loses type/safety.
- **Verify against the real contract.** Confirm field names and types against the
  actual API response / `pubspec.lock` version (see *API truthfulness*), not a
  guessed shape.

## License note
This kit is licensed separately from any project it guides. Respect each project's own license.

## Committing generated code (pointer)
How to commit is a **project-level** decision (branch strategy, commit-message
style, whether to commit `pubspec.lock` — applications should, libraries may
not). Follow the project's own `CONTRIBUTING` / git conventions; if none exist,
prefer small, descriptive commits scoped to one change. This kit does not mandate
a workflow — see *Scope* (Out of scope).

> **About the helper scripts:** the `verify`, `create_feature`, `bump_version`,
> and `build_skill` scripts mentioned above live in `scripts/` in the full
> repository at https://github.com/zero-labsco/zero-skills. This downloaded skill bundles the guidance only;
> clone the repo to run the scripts.

## Reference appendices

The following deep-dive references are bundled inline so this skill is complete
on its own — marketplaces such as skills.sh ship only `SKILL.md`.

### Plugin Platform Channel Reference

Companion to `AGENTS.md`. Template and rules for Flutter plugins that bridge to
**native code on every supported platform**: Android, iOS, Linux, macOS, Windows,
plus the browser (Web) and OpenHarmony (鸿蒙 / OHOS). The layered pattern is the
same everywhere — only the transport and native side differ.

## Layered pattern (keep this for every plugin)
1. **Platform interface** (`lib/<pkg>_platform_interface.dart`)
   - Abstract class `<Pkg>Platform extends PlatformInterface`.
   - Declares the public async API (`Future<T> doThing(...)`).
   - Provides an `instance` setter so the default impl can register itself.
2. **Concrete impl per platform** (`lib/<pkg>_method_channel.dart`, `<pkg>_web.dart`,
   `<pkg>_linux.dart`, `<pkg>_macos.dart`, `<pkg>_windows.dart`, `<pkg>_ohos.dart`, ...)
   - Each subclass extends `<Pkg>Platform` and implements the abstract API.
   - The barrel picks the right impl at runtime (see registration below).
3. **Barrel** (`lib/<pkg>.dart`)
   - Exports the public API + the platform interface; sets the default instance.
   - Never export `lib/src/` or the per-platform classes directly.

This keeps consumers calling the **abstract API only**; adding a platform never
changes consumer code.

## Registration (conditional on the running platform)
Use `dart:io` `Platform` (or `kIsWeb` from `foundation` for the browser) to pick
the implementation:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

void _registerDefaultImplementation() {
  if (kIsWeb) {
    <Pkg>Platform.instance = <Pkg>Web();
  } else if (Platform.isAndroid) {
    <Pkg>Platform.instance = <Pkg>MethodChannelPlatform();
  } else if (Platform.isIOS) {
    <Pkg>Platform.instance = <Pkg>MethodChannelPlatform();
  } else if (Platform.isLinux) {
    <Pkg>Platform.instance = <Pkg>Linux();
  } else if (Platform.isMacOS) {
    <Pkg>Platform.instance = <Pkg>Macos();
  } else if (Platform.isWindows) {
    <Pkg>Platform.instance = <Pkg>Windows();
  } else if (Platform.isOhos) {            // from `flutter_ohos` / OHOS embedding
    <Pkg>Platform.instance = <Pkg>Ohos();
  }
}
```

> `Platform.isOhos` is not part of the Dart SDK; on OpenHarmony use the
> `flutter_ohos` embedding (or detect via `Platform.operatingSystem`). The example
> above is illustrative — follow the current OHOS Flutter community API.

## Transport and native side per platform

| Platform | Transport | Native host code |
|----------|-----------|------------------|
| Android | `MethodChannel` (binary messaging) | `android/src/main/kotlin/com/example/pkg/<Pkg>Plugin.kt`; register in `onAttachedToEngine` / `registerWith`. |
| iOS | `MethodChannel` (binary messaging) | `ios/Classes/<Pkg>Plugin.swift`; register in `registerWithRegistrar`. |
| macOS | `MethodChannel` (binary messaging) | `macos/Classes/<Pkg>Plugin.swift`; same registrar pattern as iOS. |
| Linux | `MethodChannel` (binary messaging, DBus-free) | `linux/<pkg>_plugin.cc` (C++); register in the plugin registrant. |
| Windows | `MethodChannel` (binary messaging) | `windows/<pkg>_plugin.cpp` (C++); register in the plugin registrant. |
| Web | `package:js` / `dart:js_interop` (no MethodChannel) | Pure Dart talking to browser APIs / JS via `@JS` interop; `index.html` may load a JS lib. |
| OpenHarmony (鸿蒙) | `MethodChannel` via the OHOS embedding | `ohos/.../<Pkg>Plugin.ets` (ArkTS) using the Flutter OHOS plugin API. |

### Common rules for every transport
- Pass plain serializable args (Map / List / primitives); encode complex objects yourself.
- Handle `PlatformException` on the Dart side; surface a typed error, don't leak native traces.
- Native must reply on the same channel; use `result.success(...)` / `result.error(...)`.
- Keep native changes minimal; they exist only to fulfill the contract.

### Web-specific notes
Web has **no** `MethodChannel` to a native layer. Implement the same abstract API
in pure Dart using `dart:js_interop` (or the older `dart:js` / `package:js`) to call
browser APIs or a `<script>`-loaded JS library. Provide graceful degradation when a
browser API is unavailable.

### OpenHarmony (鸿蒙) notes
OHOS support is community-driven (`flutter_ohos` embedding, not yet in the official
stable SDK). The plugin pattern mirrors Android/iOS: an ArkTS plugin receives method
calls through the OHOS Flutter engine's channel and replies on the same channel.
Treat OHOS as an *opt-in* platform until it reaches official stable support, and gate
it behind a clear `isOhos` check so other platforms are unaffected.

## Method channel contract (Android / iOS / macOS / Linux / Windows / OHOS)
- One `MethodChannel('<com.example.pkg>/methods')` per plugin; method names are strings.
- Native must reply on the same channel; use `result.success(...)` / `result.error(...)`.

## Cross-platform checklist
- [ ] Declare the API once in the platform interface.
- [ ] Implement an impl for each target platform (stub + `throw UnsupportedError` is fine where a platform genuinely can't support a call).
- [ ] Register conditionally so the right impl loads at runtime.
- [ ] Add `platforms:` entries and the right `pluginClass`/`dartPluginClass` in `pubspec.yaml`.
- [ ] Document unsupported platforms in the package README.

## Release notes
- Bump `version` in `pubspec.yaml`; update `CHANGELOG.md`.
- `flutter pub publish --dry-run` before publishing; `k-paxian/dart-package-publisher` is one CI option.
- Do not pass OIDC fields to that publisher action; it uses access/refresh tokens only.
- For multi-platform plugins, verify the example builds on each target you claim support for.

### Application Architecture Reference

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

### pubspec.yaml Reference

Companion to `AGENTS.md`. Covers the fields most often mis-configured, for quick
lookup when creating or auditing a Flutter/Dart package.

## Top-level fields
- `name` — lowercase_with_underscores; must match the import prefix. Required.
- `description` — one or two sentences; required for published packages and shown on pub.dev.
- `version` — semver `x.y.z` (optionally `+build` / `-pre`). Required for publishing.
- `homepage` / `repository` / `documentation` — URLs; `repository` is where the source lives.
- `issue_tracker` — where bugs are filed. Recommended for published packages.
- `environment` — `sdk` constraint (e.g. `>=3.0.0 <4.0.0`); Flutter apps also pin `flutter`.
- `publish_to` — omit (defaults to pub.dev) or set to `none` to keep a package private.

## Dependencies
- `dependencies` — runtime deps. Prefer caret: `http: ^1.2.0`.
- `dev_dependencies` — test, lints, build_runner, etc. Not shipped to consumers.
- `dependency_overrides` — escape hatch only; never commit a permanent override.
- `flutter` — SDK assets/fonts/plugins declaration for apps and plugins.

## Constraints guidance
- Do not over-constrain the SDK; respect the oldest Flutter version you support.
- Plugins: commit `pubspec.lock` inside `example/` so CI tests a pinned resolution.
- Apps: commit `pubspec.lock` to the repo root for reproducible builds.

## Before publishing
- `flutter pub publish --dry-run` — verifies the package score and lists included files.
- Ensure `README.md`, `CHANGELOG.md`, and `LICENSE` are present (pub.dev scores them).
- Bump `version` per semver; a breaking public API change requires a major bump.

### Flutter / Dart Style Quick Reference

Companion to `AGENTS.md`. This is a **quick-lookup supplement** for the
`effective_dart` rules most often violated — not the canonical convention list.
The authoritative coding conventions (naming summary, null safety stance,
`final`/immutability, no `lib/src/` imports) live in `AGENTS.md`; this file only
adds review-time detail. Edit `AGENTS.md` for any cross-cutting rule, not here.

## Naming
- Files & directories: `snake_case.dart`
- Classes / enums / typedefs: `PascalCase`
- Variables / functions / params: `lowerCamelCase`
- Constants: `kConstant` or `lowerCamelCase` (library-private use `_kConstant`)
- Private members: leading underscore `_`

## Formatting
- Use `dart format .` — 2-space indent, no tabs.
- One class per file (library-private helpers may share a file).
- Prefer expression bodies for one-line functions: `int get width => _width;`

## Types & null safety
- Enable and rely on null safety; avoid `!` unless provably safe.
- Use `late` only when initialization is guaranteed before first read.
- Prefer `final` and immutable data classes; use `const` constructors where possible.
- Use collection `if`/`for` in widgets instead of building lists imperatively.

## Imports
- Order: `dart:` → `package:` (external) → `package:` (local) → `relative`.
- Use `show`/`hide` to narrow imports of large libraries.
- Never import another package's `lib/src/`.

## Strings
- Use template strings: `'Hello $name'` not `'Hello ' + name`.
- Use `'''` raw strings for regex / multi-line; avoid unnecessary escapes.

## Errors & async
- Throw typed exceptions; catch with `on SpecificException`.
- `await` in `async` functions; avoid `await` in loops where parallel `Future.wait` fits.
- Never swallow errors with empty `catch (_) {}` in production paths.

## Flutter widgets
- Extract reusable widgets; avoid giant `build()` methods.
- Use `const` constructors for stateless widgets.
- Prefer `ListView.builder` over `Column` of many children for dynamic lists.
- Keep `lib/` presentation layer free of direct business logic; delegate to services/state.
