import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/state/base_controller.dart';

/// Deep link Supabase sends the user back to after an OAuth sign-in or a
/// password recovery email.
///
/// Must stay in step with three things: the `CFBundleURLTypes` entry in
/// `ios/Runner/Info.plist`, the intent filter in
/// `android/app/src/main/AndroidManifest.xml`, and the Redirect URLs list in
/// the Supabase dashboard. Overridable at build time with
/// `--dart-define=AUTH_REDIRECT_URL=…`.
const String authRedirectUrl = String.fromEnvironment(
  'AUTH_REDIRECT_URL',
  defaultValue: 'app.gathermap://login-callback',
);

/// Owns the Supabase auth session for the whole app.
///
/// Holds the current [session] and republishes every change Supabase reports on
/// `onAuthStateChange`, which is what makes the UI react to a sign-in, a sign-out
/// or a token refresh without polling. Queries and mutations go through
/// [runQuery]/[runAction], so a failure is reported through [status]/[error]
/// instead of being thrown.
///
/// The constructor deliberately touches nothing: [initialize] is what reads the
/// session persisted on the device, and it is called by `AuthGate` once the
/// widget tree is up.
class AuthController extends BaseController {
  AuthController({super.service});

  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  bool _initialized = false;
  String? _pendingConfirmationEmail;
  bool _resettingPassword = false;

  /// The active session, or `null` when signed out.
  Session? get session => _session;

  /// The signed-in Supabase auth user, or `null` when signed out.
  User? get authUser => _session?.user;

  /// Id of the signed-in user — the value `auth.uid()` yields in RLS policies
  /// and the key of that user's row in `profiles`.
  String? get userId => _session?.user.id;

  /// Email address of the signed-in user.
  String? get email => _session?.user.email;

  /// True while a session is held.
  bool get isSignedIn => _session != null;

  /// True once [initialize] has run, whether or not a session was found.
  bool get isInitialized => _initialized;

  /// The address waiting for its emailed confirmation link, or `null` when no
  /// confirmation is pending.
  ///
  /// Set by a [signUp] that returned no session and by a [signIn] refused
  /// because the address is still unconfirmed. It is what lets the login screen
  /// name the address and offer the link again.
  String? get pendingConfirmationEmail => _pendingConfirmationEmail;

  /// True while an address waits for its confirmation link, i.e. after a
  /// sign-up that returned no session or a sign-in refused for
  /// `email_not_confirmed`.
  bool get awaitingEmailConfirmation => _pendingConfirmationEmail != null;

  /// True while the user is holding a session that came from a password
  /// recovery link and has not chosen a new password yet.
  ///
  /// A recovery link signs the user in, so without this the gate would drop
  /// them into the app with no way to actually change the forgotten password.
  bool get isResettingPassword => _resettingPassword;

  /// Restores the session saved on the device and starts following auth
  /// changes. Safe to call more than once; only the first call does work.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Subscribe before reading the persisted session so an event arriving in
    // between cannot be missed. The first event a new subscriber receives is
    // `initialSession`, carrying the session as of the subscription.
    _authSubscription = client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
    );
    _session = client.auth.currentSession;
    notifySafely();
  }

  void _onAuthStateChange(AuthState state) {
    _session = state.session;
    switch (state.event) {
      case AuthChangeEvent.signedIn:
        _setPendingConfirmationEmail(null);
      case AuthChangeEvent.signedOut:
        _setPendingConfirmationEmail(null);
        _resettingPassword = false;
      case AuthChangeEvent.passwordRecovery:
        // The link already produced a session; the user only still needs to
        // choose a new password.
        _resettingPassword = true;
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.mfaChallengeVerified:
        break;
    }
    notifySafely();
  }

  /// Signs in with an email and password. Returns whether it worked; the reason
  /// for a failure is in [error].
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final session = await runQuery<Session>(
      () => client.auth.signInWithPassword(email: email, password: password),
    );
    if (session != null) {
      _setPendingConfirmationEmail(null);
      return true;
    }
    // A refused sign-in still says something worth acting on: when the only
    // problem is the missing confirmation, the login screen can offer to send
    // the link again.
    if (_isEmailNotConfirmed(error)) {
      _setPendingConfirmationEmail(email);
    }
    return false;
  }

  /// Creates an account, carrying the names collected by the sign-up form in
  /// the user metadata so the `on_auth_user_created` trigger can seed the
  /// profile row.
  ///
  /// Returns whether the request was accepted. When the project asks for email
  /// confirmation this is true but no session comes back: check
  /// [awaitingEmailConfirmation].
  ///
  /// An address that already has a confirmed account is reported as a failure
  /// rather than a success, because Supabase answers it with an obfuscated user
  /// and sends nothing — see [isAlreadyRegisteredSignUp].
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? surname,
  }) async {
    final response = await runQuery<AuthResponse>(() async {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        // The confirmation link opens the app rather than the project's site
        // URL, so confirming lands the user straight in onboarding.
        emailRedirectTo: authRedirectUrl,
        data: {
          'name': ?name,
          'surname': ?surname,
        },
      );
      if (isAlreadyRegisteredSignUp(response)) {
        // Raised as a failure so the form shows it: the "check your inbox"
        // notice would promise an email that was never sent. `authErrorMessage`
        // turns the code back into French copy.
        throw const AuthException(
          'Un compte existe déjà avec cette adresse e-mail.',
          errorCode: 'user_already_exists',
        );
      }
      return response;
    });
    if (response == null) return false;
    _setPendingConfirmationEmail(response.session == null ? email : null);
    return true;
  }

  /// Sends [pendingConfirmationEmail] its confirmation link again.
  ///
  /// GoTrue rotates the token on every send, so only the newest link works —
  /// which is how an older email ends up reporting an expired link. Returns
  /// whether the request was accepted; a failure is in [error].
  Future<bool> resendConfirmationEmail() async {
    final email = _pendingConfirmationEmail;
    if (email == null) return false;

    final sent = await runQuery<bool>(() async {
      await client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: authRedirectUrl,
      );
      return true;
    });
    return sent ?? false;
  }

  /// Opens the provider's page in the system browser; the session arrives later
  /// through the deep link and shows up on [session]. Returns whether the
  /// browser was launched, not whether the sign-in succeeded.
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    final launched = await runQuery<bool>(
      () => client.auth.signInWithOAuth(
        provider,
        redirectTo: authRedirectUrl,
      ),
    );
    return launched ?? false;
  }

  /// Emails a recovery link that deep-links back into the app.
  Future<bool> sendPasswordResetEmail(String email) async {
    final sent = await runQuery<bool>(() async {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: authRedirectUrl,
      );
      return true;
    });
    return sent ?? false;
  }

  /// Replaces the password of the recovered account.
  ///
  /// Only reachable while [isResettingPassword] is true, i.e. with the
  /// temporary session a recovery link produces.
  Future<bool> updatePassword(String password) async {
    final updated = await runQuery<bool>(() async {
      await client.auth.updateUser(UserAttributes(password: password));
      return true;
    });
    if (updated != true) return false;

    _resettingPassword = false;
    notifySafely();
    return true;
  }

  /// Signs out and drops the local session. The profile cache is cleared by
  /// `ProfileController.syncSession`, which follows [userId].
  Future<void> signOut() => runAction(() async {
    await client.auth.signOut();
    _session = null;
    _setPendingConfirmationEmail(null);
    _resettingPassword = false;
  });

  /// Test-only: pretends the session is already restored, which also stops
  /// [initialize] from reaching for `Supabase.instance`. [resettingPassword]
  /// seeds the state a recovery link produces, and [pendingConfirmationEmail]
  /// the state a sign-up awaiting its confirmation email does.
  @visibleForTesting
  void setSessionForTest(
    Session? session, {
    bool resettingPassword = false,
    String? pendingConfirmationEmail,
  }) {
    _session = session;
    _resettingPassword = resettingPassword;
    _pendingConfirmationEmail = session == null
        ? pendingConfirmationEmail
        : null;
    _initialized = true;
    notifySafely();
  }

  /// True when [described] is a refusal because the address still has to be
  /// confirmed.
  ///
  /// Matched on the wording as well as on the identifier: this build of
  /// `supabase_auth` only keeps an error code when the response's `code` field
  /// is a string, while GoTrue puts the HTTP status there and the identifier in
  /// `error_code`. The identifier is tried first, so the match survives a
  /// client that does surface it.
  bool _isEmailNotConfirmed(String? described) {
    if (described == null) return false;
    return described.contains('email_not_confirmed') ||
        described.toLowerCase().contains('email not confirmed');
  }

  /// Records the address waiting for its confirmation link, announcing it only
  /// when it actually changed.
  void _setPendingConfirmationEmail(String? email) {
    if (_pendingConfirmationEmail == email) return;
    _pendingConfirmationEmail = email;
    notifySafely();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }
}

/// True when [response] is GoTrue's answer to a sign-up for an address that
/// already has a **confirmed** account.
///
/// Rather than confirming that the account exists, which would let anyone probe
/// the user list, GoTrue answers 200 with an obfuscated user — a fresh id, no
/// session and no identities — and sends nothing. Without this check the app
/// would show its "check your inbox" notice for a message that never arrives.
///
/// An address that exists but is *not* confirmed is answered differently: the
/// real user comes back, identities included, and the confirmation email is
/// sent again. That case keeps its notice.
bool isAlreadyRegisteredSignUp(AuthResponse response) =>
    response.user?.identities?.isEmpty ?? false;

/// French copy for the auth failures a user can actually cause.
///
/// [described] is [BaseController.error], i.e. `describeError`'s output —
/// Supabase's message plus whatever identifier it could recover. Two passes,
/// because the identifier does not always arrive: PostgREST sends its code in
/// `code`, but GoTrue sends the HTTP status there and the identifier in
/// `error_code`, which this build of `supabase_auth` drops. The wording is
/// matched second, in lower case, and anything unrecognised is returned
/// unchanged rather than hidden.
String authErrorMessage(String? described) {
  if (described == null || described.isEmpty) return '';

  const known = <String, String>{
    'invalid_credentials': 'Adresse e-mail ou mot de passe incorrect.',
    'email_not_confirmed': 'Confirmez votre adresse e-mail avant de vous '
        'connecter.',
    'user_already_exists': 'Un compte existe déjà avec cette adresse e-mail.',
    'email_exists': 'Un compte existe déjà avec cette adresse e-mail.',
    'weak_password': 'Mot de passe trop faible : 6 caractères minimum.',
    'over_email_send_rate_limit': 'Trop d\'e-mails envoyés. Réessayez dans '
        'quelques minutes.',
    'over_request_rate_limit': 'Trop de tentatives. Réessayez dans quelques '
        'minutes.',
    'signup_disabled': 'Les inscriptions sont fermées pour le moment.',
    'email_address_invalid': 'Cette adresse e-mail n\'est pas valide.',
    'email_address_not_authorized': 'L\'envoi d\'e-mails est limité aux '
        'adresses autorisées par le projet.',
    'otp_expired': 'Ce lien a expiré ou a déjà été utilisé. Demandez un '
        'nouvel e-mail.',
    'same_password': 'Choisissez un mot de passe différent de l\'ancien.',
  };

  // GoTrue's wording, for the failures whose identifier is lost on the way —
  // see the note above. Fragments, so a message that embeds an address or a
  // delay still matches.
  const byMessage = <String, String>{
    'invalid login credentials': 'Adresse e-mail ou mot de passe incorrect.',
    'email not confirmed': 'Confirmez votre adresse e-mail avant de vous '
        'connecter.',
    'user already registered': 'Un compte existe déjà avec cette adresse '
        'e-mail.',
    'password should be at least': 'Mot de passe trop faible : 6 caractères '
        'minimum.',
    'email rate limit exceeded': 'Trop d\'e-mails envoyés. Réessayez dans '
        'quelques minutes.',
    'you can only request this after': 'Trop d\'e-mails envoyés. Réessayez '
        'dans quelques minutes.',
    'request rate limit reached': 'Trop de tentatives. Réessayez dans '
        'quelques minutes.',
    'is not authorized': 'L\'envoi d\'e-mails est limité aux adresses '
        'autorisées par le projet.',
    'invalid or has expired': 'Ce lien a expiré ou a déjà été utilisé. '
        'Demandez un nouvel e-mail.',
    'token has expired or is invalid': 'Ce lien a expiré ou a déjà été '
        'utilisé. Demandez un nouvel e-mail.',
  };

  for (final MapEntry(key: code, value: message) in known.entries) {
    if (described.contains(code)) return message;
  }

  final lowercased = described.toLowerCase();
  for (final MapEntry(key: fragment, value: message) in byMessage.entries) {
    if (lowercased.contains(fragment)) return message;
  }

  return described;
}
