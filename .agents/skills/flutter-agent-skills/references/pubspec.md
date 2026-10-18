# pubspec.yaml Reference

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
