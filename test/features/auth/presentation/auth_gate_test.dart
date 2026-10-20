import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gathermap/core/theme/app_themes.dart';
import 'package:gathermap/core/widgets/splash_screen.dart';
import 'package:gathermap/features/auth/presentation/auth_controller.dart';
import 'package:gathermap/features/auth/presentation/auth_gate.dart';
import 'package:gathermap/features/auth/presentation/login_page.dart';
import 'package:gathermap/features/onboarding/presentation/onboarding_flow.dart';
import 'package:gathermap/features/profile/presentation/profile_controller.dart';
import 'package:gathermap/models/profile.dart';

import '../../../support/auth_harness.dart';

Session _session() => Session(
  accessToken: 'access-token',
  tokenType: 'bearer',
  refreshToken: 'refresh-token',
  expiresIn: 3600,
  user: User(
    id: 'user-1',
    audience: 'authenticated',
    createdAt: DateTime(2026, 1, 1),
    email: 'camille@example.com',
  ),
);

Profile _profile({bool onboardingCompleted = true}) => Profile(
  id: 'user-1',
  username: 'camille_d',
  name: 'Camille',
  surname: 'Durand',
  birthdate: DateTime(1995, 4, 12),
  city: 'Toulouse',
  profilePicture: null,
  privateAccount: false,
  onboardingCompleted: onboardingCompleted,
  createdAt: null,
);

/// The gate on hand-built controllers, with a stub standing in for the app.
Widget _app({
  required AuthController auth,
  required ProfileController profiles,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<ProfileController>.value(value: profiles),
    ],
    child: MaterialApp(
      theme: AppThemes.lightTheme,
      home: const AuthGate(child: Text('app-ready')),
    ),
  );
}

void main() {
  testWidgets('restoring the session is safe on the first build', (
    WidgetTester tester,
  ) async {
    // Left uninitialized on purpose: on a cold start the gate is what restores
    // the session, and `initialize` notifies as soon as it has read it.
    final auth = await authController(
      (_) async => jsonResponse({'message': 'no request expected'}),
      initialize: false,
    );
    final profiles = ProfileController();
    addTearDown(profiles.dispose);

    await tester.pumpWidget(_app(auth: auth, profiles: profiles));
    // The restore runs in a post-frame callback; let it notify and rebuild.
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(auth.isInitialized, isTrue);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('no session: the login page', (WidgetTester tester) async {
    final auth = AuthController()..setSessionForTest(null);
    final profiles = ProfileController();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);

    await tester.pumpWidget(_app(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
  });

  testWidgets('signed in but the profile has not loaded: the splash', (
    WidgetTester tester,
  ) async {
    final auth = AuthController()..setSessionForTest(_session());
    final profiles = ProfileController();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);

    await tester.pumpWidget(_app(auth: auth, profiles: profiles));
    // Bounded pump: the splash loader animates forever.
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
    expect(find.text('app-ready'), findsNothing);
  });

  testWidgets('onboarding outstanding: the flow', (WidgetTester tester) async {
    final auth = AuthController()..setSessionForTest(_session());
    final profiles = ProfileController()
      ..setCurrent(_profile(onboardingCompleted: false));
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);

    await tester.pumpWidget(_app(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(find.text('Faisons connaissance'), findsOneWidget);
    expect(find.text('app-ready'), findsNothing);
  });

  testWidgets('onboarded: the app', (WidgetTester tester) async {
    final auth = AuthController()..setSessionForTest(_session());
    final profiles = ProfileController()..setCurrent(_profile());
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);

    await tester.pumpWidget(_app(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();

    expect(find.text('app-ready'), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('a recovery session asks for a new password first', (
    WidgetTester tester,
  ) async {
    final auth = AuthController()
      ..setSessionForTest(_session(), resettingPassword: true);
    final profiles = ProfileController()..setCurrent(_profile());
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);

    await tester.pumpWidget(_app(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau mot de passe'), findsWidgets);
    expect(find.text('Enregistrer'), findsOneWidget);
    // Not the app, and not onboarding: the password comes first.
    expect(find.text('app-ready'), findsNothing);
    expect(find.byType(OnboardingFlow), findsNothing);
  });

  testWidgets('profile read failed: offer a retry rather than onboarding', (
    WidgetTester tester,
  ) async {
    final auth = AuthController()..setSessionForTest(_session());
    final profiles = ProfileController();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);

    // No Supabase client in a widget test, so the read fails and the controller
    // records it instead of throwing.
    await profiles.loadCurrent();

    await tester.pumpWidget(_app(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de charger votre profil'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
  });
}
