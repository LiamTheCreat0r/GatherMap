# Github
## Commits
|Goal|Name|
|-----|-----|
|creating a feature|Feat-(Description)|
|updating a feature|Fix-(Description)|
|adding/updating the documentation|Doc-(Description)|

## Branchs
|Goal|Name|
|-----|-----|
|adding a feature|create-(description)|
|updating a feature|update-(description)|
|patching a bug|patch-(description)|

# Code
## Formatting
|Element|Naming Convention|
|--------|------------------|
|path and files|snake_case|
|class|PascalCase|
|methods|camelCase|

## Project structure

Feature-first, with a shared core. Each feature owns its own `data/`, `domain/`
and `presentation/` slices; dependencies only ever point inward
(`presentation → domain ← data`).

    lib/
    ├── main.dart              # bootstrap: Supabase.initialize → runApp
    ├── app/
    │   ├── app.dart           # MyApp: provider scope, theme, routes
    │   └── shell/             # nav_bar_shell.dart, navbar.dart
    ├── core/                  # cross-feature, no feature imports
    │   ├── config/            # environment.dart
    │   ├── di/                # providers.dart — the only place impls are chosen
    │   ├── error/             # describe_error.dart
    │   ├── logging/           # logs.dart
    │   ├── routing/           # app_routes.dart
    │   ├── state/             # base_controller.dart
    │   ├── theme/             # app_themes, custom_colors, custom_text_styles
    │   └── widgets/           # page_header, section_title, avatar_row, loading_dots
    ├── data/
    │   └── supabase/          # supabase_service.dart
    ├── models/                # Supadart output — generated, never hand-edited
    └── features/
        └── events/
            ├── data/          # remote data source, mapper, repository impl, address_service
            ├── domain/        # entity, repository contract, pure rules
            └── presentation/  # controller, pages, widgets

## Layer rules

|Layer|May import|Must not import|
|-----|----------|---------------|
|`domain/`|other `domain/` files|Flutter, Supabase, `models/`|
|`data/`|`domain/`, `core/`, `data/`, `models/`|`presentation/`|
|`presentation/`|`domain/`, `core/`, Flutter|Supabase, `data/`|

Controllers reach I/O through a repository interface declared in `domain/`;
the Supabase implementation is selected once, in `core/di/providers.dart`.
Generated row classes stop at the mapper in `data/`.