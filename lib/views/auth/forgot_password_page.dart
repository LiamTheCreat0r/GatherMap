import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/app_themes.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/page_header.dart';
import 'auth_validators.dart';

/// Password recovery: emails a link that deep-links back into the app.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  /// True once the request has been accepted; the form is replaced by the
  /// confirmation notice, since a second send is not obviously useful.
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    final sent = await auth.sendPasswordResetEmail(_emailController.text.trim());
    if (!mounted || !sent) return;
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        children: [
          PageHeader(
            title: 'Mot de passe oublié',
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Retour',
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: _sent
                  ? _SentNotice(email: _emailController.text.trim())
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Indiquez votre adresse e-mail : nous vous '
                            'enverrons un lien pour choisir un nouveau mot de '
                            'passe.',
                            style: textStyles.bodyTextStyle.copyWith(
                              color: colors.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppTextField(
                            controller: _emailController,
                            label: 'Adresse e-mail',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.email],
                            validator: validateEmail,
                            enabled: !auth.isLoading,
                          ),
                          AppErrorText(
                            message: auth.hasError
                                ? authErrorMessage(auth.error)
                                : null,
                          ),
                          const SizedBox(height: 24),
                          AppPrimaryButton(
                            label: 'Envoyer le lien',
                            isLoading: auth.isLoading,
                            onPressed: _send,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation shown once the recovery email has been accepted.
class _SentNotice extends StatelessWidget {
  const _SentNotice({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      children: [
        Icon(Icons.mark_email_read_outlined, size: 56, color: colors.accentColor),
        const SizedBox(height: 20),
        Text(
          'E-mail envoyé',
          style: textStyles.mainTitleStyle.copyWith(
            color: colors.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Si un compte existe pour $email, le lien de réinitialisation vient '
          'de partir. Pensez à regarder dans les indésirables.',
          textAlign: TextAlign.center,
          style: textStyles.bodyTextStyle.copyWith(
            color: colors.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 28),
        AppSecondaryButton(
          label: 'Retour à la connexion',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
