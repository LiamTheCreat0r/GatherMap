import 'package:flutter/material.dart';

import '../../core/theme/custom_colors.dart';
import '../../core/theme/custom_text_styles.dart';

/// Placeholder page for the Messages tab.
///
/// Intentionally empty; replace with the real messages screen later.
class TestPage3 extends StatelessWidget {
  const TestPage3({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>();
    final textStyles = Theme.of(context).extension<CustomTextStyles>();

    return Scaffold(
      backgroundColor: colors?.mainBackgroundColor,
      body: Center(
        child: Text(
          'Test page 3',
          style: textStyles?.bodyTextStyle.copyWith(
            color: colors?.primaryTextColor,
          ),
        ),
      ),
    );
  }
}
