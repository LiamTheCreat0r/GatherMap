import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_themes.dart';
import 'shell/nav_bar_shell.dart';

/// Root widget: wires the controller layer, theme and navigation.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // One ChangeNotifier per table. `create` is lazy: a controller is only
      // built when a widget first reads it, so nothing touches Supabase at
      // startup.
      providers: [
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => EventController()),
        ChangeNotifierProvider(create: (_) => EventInvitationController()),
        ChangeNotifierProvider(create: (_) => CircleController()),
        ChangeNotifierProvider(create: (_) => CircleMemberController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => MessageController()),
        ChangeNotifierProvider(create: (_) => FriendController()),
        ChangeNotifierProvider(create: (_) => BlockedUserController()),
      ],
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
            home: const NavBarShell(),
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
