import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/core/state/base_controller.dart';
import 'package:gathermap/features/auth/presentation/auth_controller.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/auth_harness.dart';

Session _session({
  String id = 'user-1',
  String? email = 'camille@example.com',
}) => Session(
  accessToken: 'access-token',
  tokenType: 'bearer',
  refreshToken: 'refresh-token',
  expiresIn: 3600,
  user: User(
    id: id,
    audience: 'authenticated',
    createdAt: DateTime(2026, 1, 1),
    email: email,
  ),
);

void main() {
  group('AuthController state', () {
    test('starts uninitialized and signed out, without touching Supabase', () {
      final controller = AuthController();
      addTearDown(controller.dispose);

      expect(controller.isInitialized, isFalse);
      expect(controller.isSignedIn, isFalse);
      expect(controller.session, isNull);
      expect(controller.authUser, isNull);
      expect(controller.userId, isNull);
      expect(controller.email, isNull);
      expect(controller.awaitingEmailConfirmation, isFalse);
      expect(controller.pendingConfirmationEmail, isNull);
      expect(controller.status, ControllerStatus.idle);
    });

    test('exposes the session injected for tests', () async {
      final controller = AuthController();
      addTearDown(controller.dispose);
      controller.setSessionForTest(_session());

      // Once a session is in place `initialize` must stay a no-op, which is
      // what lets a widget test host the gate without Supabase being up.
      await controller.initialize();

      expect(controller.isInitialized, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(controller.authUser?.id, 'user-1');
      expect(controller.userId, 'user-1');
      expect(controller.email, 'camille@example.com');
    });

    test('an injected signed-out session reports initialized and no user', () {
      final controller = AuthController();
      addTearDown(controller.dispose);

      controller.setSessionForTest(null);

      expect(controller.isInitialized, isTrue);
      expect(controller.isSignedIn, isFalse);
      expect(controller.userId, isNull);
    });
  });

  group('signUp', () {
    test('a new address waits for its confirmation email', () async {
      final controller = await authController((request) async {
        expect(request.url.path, '/auth/v1/signup');
        return jsonResponse(userJson());
      });

      final accepted = await controller.signUp(
        email: 'camille@example.com',
        password: 'secret123',
      );

      expect(accepted, isTrue);
      expect(controller.isSignedIn, isFalse);
      expect(controller.awaitingEmailConfirmation, isTrue);
      expect(controller.pendingConfirmationEmail, 'camille@example.com');
      expect(controller.hasError, isFalse);
    });

    test('the confirmation link opens the app, not the site URL', () async {
      late Uri url;
      final controller = await authController((request) async {
        url = request.url;
        return jsonResponse(userJson());
      });

      await controller.signUp(
        email: 'camille@example.com',
        password: 'secret123',
      );

      // Silently replaced by the project's Site URL unless this scheme is in
      // the dashboard's Redirect URLs list.
      expect(url.queryParameters['redirect_to'], authRedirectUrl);
    });

    test('an address with a confirmed account is reported as taken', () async {
      // GoTrue hides the account behind a fake user with no identities, and
      // sends no email at all.
      final controller = await authController(
        (request) async => jsonResponse(userJson(withIdentity: false)),
      );

      final accepted = await controller.signUp(
        email: 'camille@example.com',
        password: 'secret123',
      );

      expect(accepted, isFalse);
      expect(controller.awaitingEmailConfirmation, isFalse);
      expect(controller.hasError, isTrue);
      expect(
        authErrorMessage(controller.error),
        'Un compte existe déjà avec cette adresse e-mail.',
      );
    });

    test('an unconfirmed address is sent the link again', () async {
      // Same shape as a new sign-up: the real user, identities included, and
      // GoTrue re-sends the confirmation.
      final controller = await authController(
        (request) async => jsonResponse(userJson()),
      );

      final accepted = await controller.signUp(
        email: 'camille@example.com',
        password: 'secret123',
      );

      expect(accepted, isTrue);
      expect(controller.awaitingEmailConfirmation, isTrue);
    });

    test('confirmation disabled: the session ends the wait', () async {
      final controller = await authController(
        (request) async => jsonResponse(sessionJson()),
      );

      final accepted = await controller.signUp(
        email: 'camille@example.com',
        password: 'secret123',
      );

      expect(accepted, isTrue);
      expect(controller.awaitingEmailConfirmation, isFalse);

      // The session reaches the controller through the auth stream, as it does
      // in the app.
      await pumpEventQueue();
      expect(controller.isSignedIn, isTrue);
    });
  });

  group('signIn', () {
    test('an unconfirmed address is offered the link again', () async {
      final controller = await authController(
        (request) async =>
            authErrorResponse(400, 'email_not_confirmed', 'Email not confirmed'),
      );

      final signedIn = await controller.signIn(
        email: 'camille@example.com',
        password: 'secret123',
      );

      expect(signedIn, isFalse);
      expect(controller.awaitingEmailConfirmation, isTrue);
      expect(controller.pendingConfirmationEmail, 'camille@example.com');
    });

    test('a wrong password does not start a confirmation', () async {
      final controller = await authController(
        (request) async => authErrorResponse(
          400,
          'invalid_credentials',
          'Invalid login credentials',
        ),
      );

      final signedIn = await controller.signIn(
        email: 'camille@example.com',
        password: 'wrong-password',
      );

      expect(signedIn, isFalse);
      expect(controller.awaitingEmailConfirmation, isFalse);
      expect(
        authErrorMessage(controller.error),
        'Adresse e-mail ou mot de passe incorrect.',
      );
    });

    test('a success clears a pending confirmation', () async {
      final controller = await authController(
        (request) async => jsonResponse(sessionJson()),
      );
      controller.setSessionForTest(
        null,
        pendingConfirmationEmail: 'camille@example.com',
      );
      expect(controller.awaitingEmailConfirmation, isTrue);

      final signedIn = await controller.signIn(
        email: 'camille@example.com',
        password: 'secret123',
      );

      expect(signedIn, isTrue);
      expect(controller.awaitingEmailConfirmation, isFalse);
      expect(controller.pendingConfirmationEmail, isNull);
    });
  });

  group('resendConfirmationEmail', () {
    test('does nothing when no address is waiting', () async {
      var calls = 0;
      final controller = await authController((request) async {
        calls++;
        return jsonResponse(const <String, Object?>{});
      });

      expect(await controller.resendConfirmationEmail(), isFalse);
      expect(calls, 0);
    });

    test('re-sends the sign-up link to the waiting address', () async {
      late http.Request sent;
      final controller = await authController((request) async {
        sent = request;
        return jsonResponse(const <String, Object?>{});
      });
      controller.setSessionForTest(
        null,
        pendingConfirmationEmail: 'camille@example.com',
      );

      expect(await controller.resendConfirmationEmail(), isTrue);
      expect(sent.url.path, '/auth/v1/resend');
      expect(sent.url.queryParameters['redirect_to'], authRedirectUrl);

      final body = jsonDecode(sent.body) as Map<String, Object?>;
      expect(body['email'], 'camille@example.com');
      expect(body['type'], 'signup');
      // Still waiting: the new link replaces the old one.
      expect(controller.awaitingEmailConfirmation, isTrue);
    });

    test('a rate limit is reported in French', () async {
      final controller = await authController(
        (request) async => authErrorResponse(
          429,
          'over_email_send_rate_limit',
          'email rate limit exceeded',
        ),
      );
      controller.setSessionForTest(
        null,
        pendingConfirmationEmail: 'camille@example.com',
      );

      expect(await controller.resendConfirmationEmail(), isFalse);
      expect(authErrorMessage(controller.error), contains('Trop d\'e-mails'));
    });
  });

  group('isAlreadyRegisteredSignUp', () {
    AuthResponse response({List<UserIdentity>? identities}) => AuthResponse(
      user: User(
        id: 'user-1',
        audience: 'authenticated',
        createdAt: DateTime(2026, 1, 1),
        identities: identities,
      ),
    );

    test('is true only for a user with an empty identity list', () {
      expect(isAlreadyRegisteredSignUp(response(identities: [])), isTrue);
      expect(isAlreadyRegisteredSignUp(response()), isFalse);
    });
  });

  group('authErrorMessage', () {
    test('names the failures a user can actually cause', () {
      expect(
        authErrorMessage('Invalid login credentials (invalid_credentials)'),
        'Adresse e-mail ou mot de passe incorrect.',
      );
      expect(
        authErrorMessage('Email not confirmed (email_not_confirmed)'),
        contains('Confirmez'),
      );
      expect(
        authErrorMessage('User already registered (user_already_exists)'),
        contains('existe déjà'),
      );
      expect(
        authErrorMessage(
          'Password should be at least 6 characters (weak_password)',
        ),
        contains('caractères minimum'),
      );
      expect(
        authErrorMessage(
          'Email rate limit exceeded (over_email_send_rate_limit)',
        ),
        contains('Trop d\'e-mails'),
      );
      expect(
        authErrorMessage('Email link is invalid or has expired (otp_expired)'),
        contains('a expiré'),
      );
    });

    test('falls back to the wording when the code is lost', () {
      // What GoTrue failures actually look like through this client build: the
      // HTTP status ends up where the identifier should be.
      expect(
        authErrorMessage('Invalid login credentials (HTTP 400)'),
        'Adresse e-mail ou mot de passe incorrect.',
      );
      expect(
        authErrorMessage('Email not confirmed (HTTP 400)'),
        contains('Confirmez'),
      );
      expect(
        authErrorMessage('email rate limit exceeded (HTTP 429)'),
        contains('Trop d\'e-mails'),
      );
      expect(
        authErrorMessage(
          'Email address "dev@example.com" cannot be used as it is not '
          'authorized (HTTP 400)',
        ),
        contains('adresses autorisées'),
      );
    });

    test('falls through to the raw message when nothing matches', () {
      expect(
        authErrorMessage('Something new (brand_new_code)'),
        'Something new (brand_new_code)',
      );
    });

    test('renders nothing for an absent error', () {
      expect(authErrorMessage(null), isEmpty);
      expect(authErrorMessage(''), isEmpty);
    });
  });
}
