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
    lib/
    ├── main.dart
    ├── models/ (Request to database)
        ├── todo.dart
        └── app_user.dart
    ├── controllers/
        ├── auth_controller.dart
        └── todo_controller.dart
    ├── views/
        ├── login_view.dart
        ├── todo_list_view.dart
        └── widgets/
    ├── services/
        └── supabase_service.dart
    └── core/
        ├── routes.dart
        └── theme.dart