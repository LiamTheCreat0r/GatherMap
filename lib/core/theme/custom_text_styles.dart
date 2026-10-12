import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextStyles extends ThemeExtension<CustomTextStyles> {
  // All Title Styles
  final TextStyle pageTitleStyle;
  final TextStyle mainTitleStyle;
  final TextStyle subTitleStyle;

  // All Body Styles
  final TextStyle bodyTextStyle;

  // All Action & Label Styles
  final TextStyle actionStyle;
  final TextStyle labelStyle;
  final TextStyle legendStyle;

  const CustomTextStyles({
    required this.pageTitleStyle,
    required this.mainTitleStyle,
    required this.subTitleStyle,
    required this.bodyTextStyle,
    required this.actionStyle,
    required this.labelStyle,
    required this.legendStyle,
  });

  static final CustomTextStyles main = CustomTextStyles(
    // All Title Styles
    pageTitleStyle: GoogleFonts.nunito(
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    mainTitleStyle: GoogleFonts.nunito(
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    subTitleStyle: GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
    // All Body Styles
    bodyTextStyle: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    // All Action & Label Styles
    actionStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
    labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
    legendStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500),
  );

  @override
  CustomTextStyles copyWith({
    TextStyle? pageTitleStyle,
    TextStyle? mainTitleStyle,
    TextStyle? subTitleStyle,
    TextStyle? bodyTextStyle,
    TextStyle? actionStyle,
    TextStyle? labelStyle,
    TextStyle? legendStyle,
  }) {
    return CustomTextStyles(
      pageTitleStyle: pageTitleStyle ?? this.pageTitleStyle,
      mainTitleStyle: mainTitleStyle ?? this.mainTitleStyle,
      subTitleStyle: subTitleStyle ?? this.subTitleStyle,
      bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
      actionStyle: actionStyle ?? this.actionStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      legendStyle: legendStyle ?? this.legendStyle,
    );
  }

  @override
  CustomTextStyles lerp(
    covariant ThemeExtension<CustomTextStyles>? other,
    double t,
  ) {
    if (other is! CustomTextStyles) return this;

    return CustomTextStyles(
      pageTitleStyle: TextStyle.lerp(pageTitleStyle, other.pageTitleStyle, t)!,
      mainTitleStyle: TextStyle.lerp(mainTitleStyle, other.mainTitleStyle, t)!,
      subTitleStyle: TextStyle.lerp(subTitleStyle, other.subTitleStyle, t)!,
      bodyTextStyle: TextStyle.lerp(bodyTextStyle, other.bodyTextStyle, t)!,
      actionStyle: TextStyle.lerp(actionStyle, other.actionStyle, t)!,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t)!,
      legendStyle: TextStyle.lerp(legendStyle, other.legendStyle, t)!,
    );
  }
}
