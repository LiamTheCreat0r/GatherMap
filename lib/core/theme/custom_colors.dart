import 'package:flutter/material.dart';

class CustomColors extends ThemeExtension<CustomColors> {
  // All Background Colors
  final Color mainBackgroundColor;
  final Color outerBackgroundColor;
  final Color discreetBackgroundColor;

  // All Surface Colors
  final Color cardColor;
  final Color secondarySurfaceColor;
  final Color translucentSurfaceColor;

  // All Border Colors
  final Color borderColor;
  final Color phoneBorderColor;

  // All Text Colors
  final Color primaryTextColor;
  final Color secondaryTextColor;

  // All Warnings Colors
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;

  const CustomColors({
    required this.mainBackgroundColor,
    required this.outerBackgroundColor,
    required this.discreetBackgroundColor,
    required this.cardColor,
    required this.secondarySurfaceColor,
    required this.translucentSurfaceColor,
    required this.borderColor,
    required this.phoneBorderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
  });

  static const CustomColors light = CustomColors(
    // All Background Colors
    mainBackgroundColor: Color.fromARGB(255, 255, 255, 255),
    outerBackgroundColor: Color.fromARGB(255, 216, 210, 202),
    discreetBackgroundColor: Color.fromARGB(38, 154, 143, 131),

    // All Surface Colors
    cardColor: Color.fromARGB(255, 247, 245, 242),
    secondarySurfaceColor: Color.fromARGB(255, 240, 237, 232),
    translucentSurfaceColor: Color.fromARGB(204, 255, 255, 255),

    // All Border Colors
    borderColor: Color.fromARGB(255, 229, 225, 219),
    phoneBorderColor: Color.fromARGB(255, 42, 42, 42),

    // All Text Colors
    primaryTextColor: Color.fromARGB(255, 26, 26, 26),
    secondaryTextColor: Color.fromARGB(255, 154, 143, 131),

    // All Warnings Colors
    successColor: Color.fromARGB(255, 34, 197, 94),
    warningColor: Color.fromARGB(255, 245, 158, 11),
    dangerColor: Color.fromARGB(255, 239, 68, 68),
  );

  static const CustomColors dark = CustomColors(
    // All Background Colors
    mainBackgroundColor: Color.fromARGB(255, 18, 16, 15),
    outerBackgroundColor: Color.fromARGB(255, 8, 7, 6),
    discreetBackgroundColor: Color.fromARGB(38, 184, 174, 164),

    // All Surface Colors
    cardColor: Color.fromARGB(255, 28, 25, 23),
    secondarySurfaceColor: Color.fromARGB(255, 38, 33, 30),
    translucentSurfaceColor: Color.fromARGB(229, 28, 25, 23),

    // All Border Colors
    borderColor: Color.fromARGB(255, 58, 51, 46),
    phoneBorderColor: Color.fromARGB(255, 5, 5, 5),

    // All Text Colors
    primaryTextColor: Color.fromARGB(255, 247, 245, 242),
    secondaryTextColor: Color.fromARGB(255, 184, 174, 164),

    // All Warnings Colors
    successColor: Color.fromARGB(255, 34, 197, 94),
    warningColor: Color.fromARGB(255, 245, 158, 11),
    dangerColor: Color.fromARGB(255, 239, 68, 68),
  );

  @override
  CustomColors copyWith({
    Color? mainBackgroundColor,
    Color? outerBackgroundColor,
    Color? discreetBackgroundColor,
    Color? cardColor,
    Color? secondarySurfaceColor,
    Color? translucentSurfaceColor,
    Color? borderColor,
    Color? phoneBorderColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? successColor,
    Color? warningColor,
    Color? dangerColor,
  }) {
    return CustomColors(
      mainBackgroundColor: mainBackgroundColor ?? this.mainBackgroundColor,
      outerBackgroundColor: outerBackgroundColor ?? this.outerBackgroundColor,
      discreetBackgroundColor:
          discreetBackgroundColor ?? this.discreetBackgroundColor,
      cardColor: cardColor ?? this.cardColor,
      secondarySurfaceColor:
          secondarySurfaceColor ?? this.secondarySurfaceColor,
      translucentSurfaceColor:
          translucentSurfaceColor ?? this.translucentSurfaceColor,
      borderColor: borderColor ?? this.borderColor,
      phoneBorderColor: phoneBorderColor ?? this.phoneBorderColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      dangerColor: dangerColor ?? this.dangerColor,
    );
  }

  @override
  CustomColors lerp(covariant ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;

    return CustomColors(
      mainBackgroundColor: Color.lerp(
        mainBackgroundColor,
        other.mainBackgroundColor,
        t,
      )!,
      outerBackgroundColor: Color.lerp(
        outerBackgroundColor,
        other.outerBackgroundColor,
        t,
      )!,
      discreetBackgroundColor: Color.lerp(
        discreetBackgroundColor,
        other.discreetBackgroundColor,
        t,
      )!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      secondarySurfaceColor: Color.lerp(
        secondarySurfaceColor,
        other.secondarySurfaceColor,
        t,
      )!,
      translucentSurfaceColor: Color.lerp(
        translucentSurfaceColor,
        other.translucentSurfaceColor,
        t,
      )!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      phoneBorderColor: Color.lerp(
        phoneBorderColor,
        other.phoneBorderColor,
        t,
      )!,
      primaryTextColor: Color.lerp(
        primaryTextColor,
        other.primaryTextColor,
        t,
      )!,
      secondaryTextColor: Color.lerp(
        secondaryTextColor,
        other.secondaryTextColor,
        t,
      )!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      dangerColor: Color.lerp(dangerColor, other.dangerColor, t)!,
    );
  }
}
