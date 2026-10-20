import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/shell/nav_bar_shell.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/splash_screen.dart';
import '../../onboarding/presentation/onboarding_flow.dart';
import '../../profile/presentation/profile_controller.dart';
import 'auth_controller.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

/// Decides what the app shows for the current account, for the whole run.
///
/// Four states, in order:
///
///  * the session has not been restored yet — [SplashScreen];
///  * no session — [LoginPage];
///  * a session from a password recovery link — [ResetPasswordPage];
///  * a session whose profile has not loaded yet — [SplashScreen];
///  * a profile that has not finished onboarding — [OnboardingFlow];
///  * otherwise the app itself, [child].
///
/// It is the only place that calls [AuthController.initialize], which is what
/// keeps the controllers free of Supabase access at construction time.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.child});

  /// What to show once the user is signed in and onboarded. Defaults to the
  /// tabbed [NavBarShell].
  final Widget? child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Restores the session saved on the device and starts following auth
    // changes. Deferred to after the frame because `initialize` notifies its
    // listeners as soon as it has read the session, and notifying during this
    // first build would mark the provider dirty mid-build. The splash this
    // leaves on screen for one frame is the one the gate opens with anyway.
    //
    // `read` rather than `watch`: this must not rebuild on itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isInitialized) return const SplashScreen();
    if (!auth.isSignedIn) return const LoginPage();

    // A recovery link signs the user in, so this has to come before the app:
    // the forgotten password still needs replacing.
    if (auth.isResettingPassword) return const ResetPasswordPage();

    final profile = context.watch<ProfileController>();
    if (!profile.isLoaded) return const SplashScreen();
    if (!profile.hasProfile && profile.hasError) {
      return _ProfileLoadFailed(message: profile.error);
    }
    if (!profile.isOnboardingComplete) return const OnboardingFlow();

    return widget.child ?? const NavBarShell();
  }
}

/// Shown when the signed-in user's profile could not be read.
///
/// Retrying is the only sensible action: without the row the app cannot tell
/// whether onboarding is still owed.
class _ProfileLoadFailed extends StatelessWidget {
  const _ProfileLoadFailed({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.mainBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 56,
                color: context.colors.secondaryTextColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Impossible de charger votre profil',
                textAlign: TextAlign.center,
                style: context.textStyles.mainTitleStyle.copyWith(
                  color: context.colors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              AppErrorText(message: message),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Réessayer',
                isLoading: context.watch<ProfileController>().isLoading,
                onPressed: () => context.read<ProfileController>().loadCurrent(),
              ),
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Se déconnecter',
                onPressed: () => context.read<AuthController>().signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
