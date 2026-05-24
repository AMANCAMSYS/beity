import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

class BeityTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final int maxLines;
  final int? maxLength;
  final TextDirection? textDirection;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool enabled;
  final TextInputAction? textInputAction;

  const BeityTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.textDirection,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.enabled = true,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: labelText ?? hintText ?? 'Input field',
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        textDirection: textDirection ?? TextDirection.rtl,
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        enabled: enabled,
        textInputAction: textInputAction,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: isDark ? null : theme.colorScheme.onSurfaceVariant)
              : null,
          suffixIcon: suffixIcon,
          counterText: maxLength != null ? null : '',
        ),
      ),
    );
  }
}
