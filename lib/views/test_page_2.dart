import 'package:flutter/material.dart';

import '../../core/theme/custom_colors.dart';
import '../../core/theme/custom_text_styles.dart';

/// Placeholder page for the Map tab.
///
/// Intentionally empty; replace with the real map screen later.
class TestPage2 extends StatelessWidget {
  const TestPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>();
    final textStyles = Theme.of(context).extension<CustomTextStyles>();

    return Scaffold(
      backgroundColor: colors?.mainBackgroundColor,
      body: Center(
        child: Text(
          'Test page 2',
          style: textStyles?.bodyTextStyle.copyWith(
            color: colors?.primaryTextColor,
          ),
        ),
      ),
    );
  }
}
