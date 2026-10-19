import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/controllers.dart';
import 'core/route.dart';
import 'core/theme/app_themes.dart';
import 'views/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  // if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
  //   throw StateError(
  //     'Missing Supabase config. Run with --dart-define-from-file=env.json',
  //   );
  // }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
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
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Wires every controller into the widget tree.
///
/// `create` is lazy: a controller is only built when a widget first reads it, so
/// nothing touches Supabase at startup — the session is restored later, by
/// `AuthGate` calling [AuthController.initialize].
///
/// Separate from [MyApp] so a widget test can host a single screen on the same
/// controllers without going through the gate.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),

        // One controller per table. The profile cache is not per-table: it
        // follows the session, so it is a proxy over AuthController —
        // `syncSession` loads the row on a sign-in and clears it on a sign-out.
        ChangeNotifierProxyProvider<AuthController, ProfileController>(
          create: (_) => ProfileController(),
          update: (_, auth, profile) => profile!..syncSession(auth.userId),
        ),

        ChangeNotifierProvider(create: (_) => EventController()),
        ChangeNotifierProvider(create: (_) => EventInvitationController()),
        ChangeNotifierProvider(create: (_) => CircleController()),
        ChangeNotifierProvider(create: (_) => CircleMemberController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => MessageController()),
        ChangeNotifierProvider(create: (_) => FriendController()),
        ChangeNotifierProvider(create: (_) => BlockedUserController()),
      ],
      child: child,
    );
  }
}
