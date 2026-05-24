import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

enum BeityButtonType { primary, secondary, outline, text, destructive }

class BeityButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final BeityButtonType type;
  final IconData? icon;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;

  const BeityButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = BeityButtonType.primary,
    this.icon,
    this.width,
    this.padding,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? border;

    switch (type) {
      case BeityButtonType.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        break;
      case BeityButtonType.secondary:
        backgroundColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
        foregroundColor = colorScheme.onSurface;
        break;
      case BeityButtonType.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.primary;
        border = BorderSide(color: foregroundColor, width: 1.5);
        break;
      case BeityButtonType.text:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.primary;
        break;
      case BeityButtonType.destructive:
        backgroundColor = colorScheme.error;
        foregroundColor = colorScheme.onError;
        break;
    }

    if (onPressed == null && !isLoading) {
      backgroundColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
      foregroundColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.55);
      if (type == BeityButtonType.outline) {
        backgroundColor = Colors.transparent;
        border = BorderSide(color: foregroundColor, width: 1.5);
      } else if (type == BeityButtonType.text) {
        backgroundColor = Colors.transparent;
      }
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final ButtonStyle baseStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all(backgroundColor),
      foregroundColor: WidgetStateProperty.all(foregroundColor),
      overlayColor: WidgetStateProperty.all(foregroundColor.withValues(alpha: 0.1)),
      padding: WidgetStateProperty.all(
        padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: border ?? BorderSide.none,
        ),
      ),
      elevation: WidgetStateProperty.all(0),
      minimumSize: WidgetStateProperty.all(const Size(0, 48)),
    );

    Widget button;
    if (type == BeityButtonType.text) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: baseStyle,
        child: content,
      );
    } else if (type == BeityButtonType.outline) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: baseStyle,
        child: content,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: baseStyle,
        child: content,
      );
    }

    if (fullWidth || width != null) {
      return SizedBox(
        width: fullWidth ? double.infinity : width,
        child: button,
      );
    }
    return button;
  }
}
