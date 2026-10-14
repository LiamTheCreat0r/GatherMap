import 'package:flutter/material.dart';
import 'custom_colors.dart';
import 'custom_text_styles.dart';

extension ThemeContext on BuildContext {
  CustomColors get colors => Theme.of(this).extension<CustomColors>()!;
  CustomTextStyles get textStyles =>
      Theme.of(this).extension<CustomTextStyles>()!;
}

class AppThemes {
  static const Color primaryBrand = Color.fromARGB(255, 242, 100, 25);

  /// Current theme mode for the whole app.
  ///
  /// Starts on [ThemeMode.system] so the app follows the device setting, but
  /// can be forced to light or dark from a settings screen by assigning to
  /// [themeModeValue].
  static final ValueNotifier<ThemeMode> themeModeValue = ValueNotifier(
    ThemeMode.system,
  );

  /// Convenience getter for the current mode.
  static ThemeMode get themeMode => themeModeValue.value;

  /// Force the app to a specific [mode] (light, dark, or back to system).
  static void setThemeMode(ThemeMode mode) => themeModeValue.value = mode;

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBrand,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: CustomColors.light.mainBackgroundColor,
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
    scaffoldBackgroundColor: CustomColors.dark.mainBackgroundColor,
    extensions: <ThemeExtension<dynamic>>[
      CustomColors.dark,
      CustomTextStyles.main,
    ],
  );
}
