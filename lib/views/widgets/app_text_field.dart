import 'package:flutter/material.dart';

import '../../core/theme/app_themes.dart';

/// Text field styled from the app theme, used by every auth and onboarding form.
///
/// Passing `obscureText: true` also adds the show/hide toggle, so password
/// fields do not each need their own state. Colours and text styles come from
/// the `CustomColors` and `CustomTextStyles` theme extensions, which keeps light
/// and dark mode working with no branching here.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.autofillHints,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;

  /// Floating label above the field.
  final String label;

  /// Optional helper text shown when the field is empty.
  final String? hint;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Whether to hide the value and offer the show/hide toggle.
  final bool obscureText;

  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscured,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      style: textStyles.bodyTextStyle.copyWith(
        color: colors.primaryTextColor,
      ),
      cursorColor: colors.accentColor,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        filled: true,
        fillColor: colors.cardColor,
        labelStyle: textStyles.bodyTextStyle.copyWith(
          color: colors.secondaryTextColor,
        ),
        hintStyle: textStyles.bodyTextStyle.copyWith(
          color: colors.secondaryTextColor,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(colors.borderColor),
        enabledBorder: border(colors.borderColor),
        focusedBorder: border(colors.accentColor, 2),
        errorBorder: border(colors.dangerColor),
        focusedErrorBorder: border(colors.dangerColor, 2),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                tooltip: _obscured ? 'Afficher' : 'Masquer',
                icon: Icon(
                  _obscured ? Icons.visibility_off : Icons.visibility,
                  color: colors.secondaryTextColor,
                ),
              )
            : null,
      ),
    );
  }
}
