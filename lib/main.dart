import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/route.dart';
import 'core/theme/app_themes.dart';
import 'views/widgets/nav_bar_shell.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemes.themeModeValue,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'GatherMap',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: mode,
          navigatorObservers: [currentRouteObserver],
          onGenerateRoute: _onGenerateRoute,
          home: const NavBarShell(),
        );
      },
    );
  }
}

/// Handles the named routes declared in [AppRoutes].
///
/// Only the nav-hiding detail routes are wired up for now; the four tab pages
/// are hosted directly by [NavBarShell] and are not pushed as routes.
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  // Checked before the generic detail branch below: the `/events/:id` wildcard
  // also matches `/events/new`, so the exact create route must win.
  if (settings.name == AppRoutes.eventCreate) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const _EventCreatePlaceholder(),
    );
  }
  if (AppRoutes.isNavHidden(settings.name)) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const _EventDetailPlaceholder(),
    );
  }
  return null;
}

/// Stand-in for the real create-event screen opened from the map's FAB.
class _EventCreatePlaceholder extends StatelessWidget {
  const _EventCreatePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Create event')));
  }
}

/// Stand-in for the real event detail screen.
///
/// Its only job right now is to prove that pushing a detail route hides the
/// bottom navigation bar, and popping it brings the bar back.
class _EventDetailPlaceholder extends StatelessWidget {
  const _EventDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Event details')));
  }
}
