import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/page_header.dart';
import 'auth_controller.dart';
import 'auth_validators.dart';

/// Account creation.
///
/// The first and last names are sent as user metadata, so the
/// `on_auth_user_created` trigger can seed the profile row; the username and the
/// rest of the profile are collected by the onboarding flow once the account
/// exists.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    final created = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
    );
    if (!mounted || !created) return;

    // Back to the gate: it shows the app when Supabase returned a session
    // (confirmation disabled) and the login screen, with its "confirm your
    // email" notice, when it did not.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        children: [
          PageHeader(
            title: 'Créer un compte',
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Retour',
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Prénom',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        validator: validateRequired,
                        enabled: !auth.isLoading,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _surnameController,
                        label: 'Nom',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        validator: validateRequired,
                        enabled: !auth.isLoading,
                      ),
                      const SizedBox(height: 16),
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
                        label: 'Créer mon compte',
                        isLoading: auth.isLoading,
                        onPressed: _signUp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
