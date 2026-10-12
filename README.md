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
