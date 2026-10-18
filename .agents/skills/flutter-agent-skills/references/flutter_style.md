# Flutter / Dart Style Quick Reference

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
