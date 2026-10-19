import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/controllers/auth_controller.dart';
import 'package:gathermap/services/supabase_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// An [AuthController] backed by a stubbed HTTP client, already initialized.
///
/// The auth calls run for real — request building, PKCE, error parsing — with
/// [handler] standing in for GoTrue, so a test can assert on what goes out and
/// on what the controller makes of what comes back, without a network.
///
/// Pass `initialize: false` to hand the controller to `AuthGate` uninitialized,
/// which is what exercises the gate's own session restore.
Future<AuthController> authController(
  Future<http.Response> Function(http.Request request) handler, {
  bool initialize = true,
}) async {
  final client = SupabaseClient(
    'http://localhost:9999',
    'sb_publishable_test',
    httpClient: MockClient(handler),
    authOptions: AuthClientOptions(
      // Nothing may outlive the test: no background refresh timer, and the
      // session and pkce verifiers stay in memory.
      autoRefreshToken: false,
      asyncStorage: MemoryAuthAsyncStorage(),
      persistSession: true,
    ),
  );
  final controller = AuthController(service: SupabaseService(client: client));

  addTearDown(controller.dispose);
  addTearDown(client.dispose);

  // Same entry point as `AuthGate`, so the signed-in state is driven by the
  // same auth stream as in the app.
  if (initialize) await controller.initialize();
  return controller;
}

/// A JSON response shaped like GoTrue's.
http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// GoTrue's error body: the HTTP status goes in `code`, the identifier in
/// `error_code`.
http.Response authErrorResponse(
  int status,
  String code,
  String message,
) => jsonResponse({
  'code': status,
  'error_code': code,
  'msg': message,
}, status);

/// The `user` GoTrue returns on sign-up.
///
/// [withIdentity] false is the obfuscated object it answers for an address that
/// already has a confirmed account: no identities, hence no email sent.
Map<String, Object?> userJson({
  String id = 'user-1',
  String email = 'camille@example.com',
  bool withIdentity = true,
}) => {
  'id': id,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': email,
  'created_at': '2026-01-01T00:00:00Z',
  'identities': [
    if (withIdentity) {'id': 'identity-1', 'user_id': id, 'provider': 'email'},
  ],
};

/// The token response GoTrue sends when "Confirm email" is off.
Map<String, Object?> sessionJson({
  String id = 'user-1',
  String email = 'camille@example.com',
}) => {
  'access_token': 'access-token',
  'token_type': 'bearer',
  'refresh_token': 'refresh-token',
  'expires_in': 3600,
  'user': userJson(id: id, email: email),
};
