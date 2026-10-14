import 'package:flutter/material.dart';

import '../../core/theme/custom_colors.dart';
import '../../core/theme/custom_text_styles.dart';

/// Reusable orange page header holding the page title.
///
/// Fills the status bar area with the theme's accent colour and keeps the
/// title clear of the notch/cutout. Colours and text styles come from the
/// [CustomColors] and [CustomTextStyles] theme extensions, so light and dark
/// mode are handled by the active theme with no branching here.
///
/// Optional [leading] (e.g. a back button) and [trailing] (e.g. an action)
/// slots can be supplied by pages that need them.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  /// Page title, rendered left-aligned in white.
  final String title;

  /// Optional widget shown before the title, such as a back button.
  final Widget? leading;

  /// Optional widget shown after the title, such as an action button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;

    // Let the orange fill the status bar area, and keep the title clear of the
    // notch/cutout.
    final topInset = MediaQuery.of(context).padding.top;

    return ColoredBox(
      color: colors.accentColor,
      child: Padding(
        padding: EdgeInsets.only(
          top: topInset + 12,
          left: 20,
          right: 20,
          bottom: 16,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Text(
                title,
                style: textStyles.pageTitleStyle.copyWith(color: Colors.white),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
