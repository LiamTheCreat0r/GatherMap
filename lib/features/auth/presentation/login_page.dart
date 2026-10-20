import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'auth_validators.dart';
import 'forgot_password_page.dart';
import 'sign_up_page.dart';

/// Email/password sign-in, with the third-party providers underneath.
///
/// This is the screen the gate shows whenever there is no session, so it is the
/// root of the auth flow: the sign-up and password-recovery screens are pushed
/// on top of it, and the app itself replaces it once [AuthController] reports a
/// session.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    // The gate swaps this page out as soon as the session lands, so a success
    // needs nothing beyond letting the controller notify.
    await context.read<AuthController>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final auth = context.read<AuthController>();
    final launched = await auth.signInWithOAuth(provider);
    if (!mounted || launched) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authErrorMessage(auth.error))),
    );
  }

  /// Asks for a fresh confirmation link. A failure is left to the inline error
  /// text, which reports the rate limit in French.
  Future<void> _resendConfirmationEmail() async {
    final auth = context.read<AuthController>();
    final sent = await auth.resendConfirmationEmail();
    if (!mounted || !sent) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nouvel e-mail de confirmation envoyé.')),
    );
  }

  void _open(Widget page, String routeName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'GatherMap',
                      textAlign: TextAlign.center,
                      style: textStyles.pageTitleStyle.copyWith(
                        color: colors.accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Retrouvez vos amis, organisez vos sorties.',
                      textAlign: TextAlign.center,
                      style: textStyles.bodyTextStyle.copyWith(
                        color: colors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 36),
                    AppTextField(
                      controller: _emailController,
                      label: 'Adresse e-mail',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: validateEmail,
                      enabled: !auth.isLoading,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: validateRequired,
                      enabled: !auth.isLoading,
                    ),
                    AppErrorText(
                      message: auth.hasError
                          ? authErrorMessage(auth.error)
                          : null,
                    ),
                    if (auth.awaitingEmailConfirmation) ...[
                      const SizedBox(height: 12),
                      _ConfirmationNotice(
                        color: colors.successColor,
                        email: auth.pendingConfirmationEmail,
                        isSending: auth.isLoading,
                        onResend: _resendConfirmationEmail,
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Se connecter',
                      isLoading: auth.isLoading,
                      onPressed: _signIn,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => _open(
                                const ForgotPasswordPage(),
                                AppRoutes.forgotPassword,
                              ),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.secondaryTextColor,
                        ),
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _OrDivider(color: colors.borderColor),
                    const SizedBox(height: 16),
                    AppSecondaryButton(
                      label: 'Continuer avec Google',
                      isLoading: auth.isLoading,
                      onPressed: () =>
                          _signInWithOAuth(OAuthProvider.google),
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Continuer avec Apple',
                      isLoading: auth.isLoading,
                      onPressed: () => _signInWithOAuth(OAuthProvider.apple),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ?',
                          style: textStyles.bodyTextStyle.copyWith(
                            color: colors.secondaryTextColor,
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => _open(
                                  const SignUpPage(),
                                  AppRoutes.signUp,
                                ),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.accentColor,
                          ),
                          child: Text(
                            'Créer un compte',
                            style: textStyles.actionStyle.copyWith(
                              color: colors.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Notice shown on the login screen while an address waits for its emailed
/// confirmation link, so the user is not left wondering why signing in fails.
///
/// The link can be requested again from here: confirmation tokens are rotated
/// on every send and single-use, so a lost or prefetched email is routine and
/// the dashboard should not be the only way out.
class _ConfirmationNotice extends StatelessWidget {
  const _ConfirmationNotice({
    required this.color,
    required this.email,
    required this.isSending,
    required this.onResend,
  });

  final Color color;
  final String? email;
  final bool isSending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final address = email;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mark_email_unread_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address == null
                      ? 'Ce compte attend d\'être activé. Ouvrez le lien de '
                            'confirmation reçu par e-mail.'
                      : 'Ce compte attend d\'être activé. Ouvrez le lien de '
                            'confirmation envoyé à $address.',
                  style: context.textStyles.bodyTextStyle.copyWith(
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isSending ? null : onResend,
              style: TextButton.styleFrom(foregroundColor: color),
              child: const Text('Renvoyer l\'e-mail'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal rule with a centred "ou", separating the two sign-in styles.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: context.textStyles.labelStyle.copyWith(color: color),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}
