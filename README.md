# Gather Map

## Supabase Configuration

Pull your project down

```bash
npm i -g supabase          # or: brew install supabase/tap/supabase
supabase login
supabase init              # creates supabase/ folder with config.toml
supabase link --project-ref <your-project-ref>
```

Schema (tables, RLS, functions, triggers)

```bash
supabase db pull
```

Data (optional)

```bash
supabase db dump --data-only -f supabase/seed.sql
```

Run database

```bash
supabase start && supabase db reset
```

## Dart type generation

Model types are generated from the linked project's schema — one file per
table in `lib/models/` (`event.dart` → `EventRow` with typed getters,
`EventInsert`, `EventUpdate`, class `Event` with column tokens), plus
`lib/models/typegen_helpers.dart`. Regenerate with:

```bash
tool/gen_types.sh
```

This runs `supabase_typegen` (needs the supabase CLI and `supabase login`)
and splits the output via `tool/split_schema.dart`. Never edit the generated
files by hand — hand-written files in `lib/models/` (like `todo.dart`) are
left alone.

Enable the pre-commit hook once per clone; it regenerates when `supabase/**`,
`schema.sql`, `pubspec.yaml`, or `lib/models/*` are staged and blocks the
commit if any generated file drifts or is missing:

```bash
git config core.hooksPath .githooks
```

## Supabase Configuration

```bash
# Initialize supadart.yaml config file
supadart --init

# Generate classes
supadart --url <supabase_url> --key <supabase_secret_key>

# if SUPABASE_URL and SUPABASE_API_KEY are set in the environment variables
# if SUPABASE_URL and SUPABASE_API_KEY are set in supadart.yaml
supadart

# Generate from schemas other than public (the first keeps plain names)
supadart --schema public,inventory
```
