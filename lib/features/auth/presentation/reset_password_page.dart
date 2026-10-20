import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'auth_validators.dart';

/// Shown when the user arrives through a password recovery link.
///
/// The link already signs them in, so the only thing left is a new password. It
/// is a gate screen rather than a pushed route: nothing else of the app is
/// reachable until the password is chosen (or recovery is abandoned).
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    // On success the controller clears the recovery flag and the gate swaps
    // this page for onboarding or the app.
    await context.read<AuthController>().updatePassword(
      _passwordController.text,
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nouveau mot de passe',
                    textAlign: TextAlign.center,
                    style: textStyles.mainTitleStyle.copyWith(
                      color: colors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez un mot de passe pour '
                    '${auth.email ?? 'votre compte'}.',
                    textAlign: TextAlign.center,
                    style: textStyles.bodyTextStyle.copyWith(
                      color: colors.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Nouveau mot de passe',
                    hint: 'Au moins $kMinPasswordLength caractères',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: validatePassword,
                    enabled: !auth.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmationController,
                    label: 'Confirmer le mot de passe',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: validatePasswordConfirmation(
                      _passwordController,
                    ),
                    enabled: !auth.isLoading,
                  ),
                  AppErrorText(
                    message: auth.hasError
                        ? authErrorMessage(auth.error)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'Enregistrer',
                    isLoading: auth.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => context.read<AuthController>().signOut(),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.secondaryTextColor,
                    ),
                    child: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
