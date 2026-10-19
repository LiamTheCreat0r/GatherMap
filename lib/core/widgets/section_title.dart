import 'package:flutter/material.dart';

import '../theme/custom_colors.dart';
import '../theme/custom_text_styles.dart';

/// Small uppercase heading that introduces a list section.
///
/// Shared by the Events and Messages tabs so both read as one design.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.label,
    required this.textStyles,
    required this.colors,
  });

  /// Section heading, e.g. "À VENIR".
  final String label;

  /// Theme text styles, passed in so the caller controls the look-up.
  final CustomTextStyles textStyles;

  /// Theme colours, passed in for the same reason.
  final CustomColors colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: textStyles.legendStyle.copyWith(
          color: colors.secondaryTextColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
