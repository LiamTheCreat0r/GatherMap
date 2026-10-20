import 'package:flutter/material.dart';

import '../theme/app_themes.dart';

/// Full-width call to action, filled with the brand colour.
///
/// While [isLoading] the label makes way for a spinner and the button stops
/// responding, which is what a form needs while its request is in flight.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accentColor,
          disabledBackgroundColor: colors.accentColor.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: context.textStyles.actionStyle.copyWith(fontSize: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Full-width outlined action, used for the OAuth providers and secondary
/// choices next to [AppPrimaryButton].
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryTextColor,
          backgroundColor: colors.cardColor,
          side: BorderSide(color: colors.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: context.textStyles.actionStyle.copyWith(fontSize: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: colors.accentColor,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Inline failure message shown under a form.
///
/// Renders nothing when [message] is empty, so callers can pass a nullable
/// error straight through.
class AppErrorText extends StatelessWidget {
  const AppErrorText({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: context.colors.dangerColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodyTextStyle.copyWith(
                color: context.colors.dangerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
