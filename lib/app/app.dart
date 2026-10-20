import 'package:flutter/material.dart';

import '../core/di/providers.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_themes.dart';
import '../features/auth/presentation/auth_gate.dart';

/// Root widget: wires the controller layer, theme and navigation.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return buildProviderScope(
      child: ValueListenableBuilder<ThemeMode>(
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
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Handles the named routes declared in [AppRoutes].
///
/// Only the nav-hiding detail routes are wired up for now; the four tab pages
/// are hosted directly by [NavBarShell] and are not pushed as routes. The
/// create-event window is not a route — it is shown over the map rather than
/// pushed onto the navigator.
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  if (AppRoutes.isNavHidden(settings.name)) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const _EventDetailPlaceholder(),
    );
  }
  return null;
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
