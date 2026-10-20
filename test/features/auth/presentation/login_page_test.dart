import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gathermap/core/theme/app_themes.dart';
import 'package:gathermap/features/auth/presentation/auth_controller.dart';
import 'package:gathermap/features/auth/presentation/login_page.dart';

import '../../../support/auth_harness.dart';

Widget _app(AuthController auth) =>
    ChangeNotifierProvider<AuthController>.value(
      value: auth,
      child: MaterialApp(theme: AppThemes.lightTheme, home: const LoginPage()),
    );

void main() {
  testWidgets('a pending confirmation names the address and offers the link '
      'again', (WidgetTester tester) async {
    final auth = await authController(
      (request) async => jsonResponse(const <String, Object?>{}),
    );
    auth.setSessionForTest(null, pendingConfirmationEmail: 'camille@example.com');

    await tester.pumpWidget(_app(auth));
    await tester.pump();

    expect(find.textContaining('camille@example.com'), findsOneWidget);
    expect(find.text('Renvoyer l\'e-mail'), findsOneWidget);
  });

  testWidgets('the notice button asks for a new link and confirms it', (
    WidgetTester tester,
  ) async {
    var resendCalls = 0;
    final auth = await authController((request) async {
      expect(request.url.path, '/auth/v1/resend');
      resendCalls++;
      return jsonResponse(const <String, Object?>{});
    });
    auth.setSessionForTest(null, pendingConfirmationEmail: 'camille@example.com');

    await tester.pumpWidget(_app(auth));
    await tester.pump();

    final button = find.text('Renvoyer l\'e-mail');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(resendCalls, 1);
    expect(find.text('Nouvel e-mail de confirmation envoyé.'), findsOneWidget);
    // Still waiting: the new link replaces the previous one.
    expect(auth.awaitingEmailConfirmation, isTrue);
  });
}
