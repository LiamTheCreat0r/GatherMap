import 'package:flutter/material.dart';

import '../../core/theme/app_themes.dart';
import 'loading_dots.dart';

/// Blank branded screen shown while the session is restored and the signed-in
/// user's profile is fetched.
///
/// It exists so the first frame after launch is never a login form for a user
/// who is in fact signed in, nor the tab bar of a user who is not.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.mainBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GatherMap',
              style: context.textStyles.pageTitleStyle.copyWith(
                color: context.colors.accentColor,
              ),
            ),
            const SizedBox(height: 28),
            LoadingDots(color: context.colors.accentColor),
          ],
        ),
      ),
    );
  }
}
