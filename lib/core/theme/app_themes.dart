import 'package:flutter/material.dart';
import 'custom_colors.dart';
import 'custom_text_styles.dart';

class AppThemes {
  static const Color primaryBrand = Color.fromARGB(255, 242, 100, 25);

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBrand,
      brightness: Brightness.light,
    ),
    extensions: <ThemeExtension<dynamic>>[
      CustomColors.light,
      CustomTextStyles.main,
    ],
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBrand,
      brightness: Brightness.dark,
    ),
    extensions: <ThemeExtension<dynamic>>[
      CustomColors.dark,
      CustomTextStyles.main,
    ],
  );
}
