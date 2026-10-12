# Github
## Commits
|But du Commit|Nom du Commit|
|--------|------------------|
|Création|Feat-(Description)|
|Modification|Fix-(Description)|
|Documentation|Doc-(Description)|

## Branches
|But de la Branche|Nom de la Branche|
|--------|------------------|
|Ajout d'une fonctionnalité|Create-(Description)|
|Modification d'une fonctionnalité|Update-(Description)|
|Resolution d'un bug|Patch-(Description)|

# Code
## Formattage
|Element|Convention de Nommage|
|--------|------------------|
|path et fichiers|snake_case|
|classe|PascalCase|
|méthodes|camelCase|

## Structure projet
    lib/
    ├── main.dart
    ├── models/ (Requetes à la base de donnée)
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