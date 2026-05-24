import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

enum BeityButtonType { primary, secondary, outline, text }

class BeityButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final BeityButtonType type;
  final IconData? icon;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const BeityButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = BeityButtonType.primary,
    this.icon,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? border;

    switch (type) {
      case BeityButtonType.primary:
        backgroundColor = isDark ? AppColors.primaryLight : AppColors.primary;
        foregroundColor = isDark ? Colors.black : Colors.white;
        break;
      case BeityButtonType.secondary:
        backgroundColor = isDark ? AppColors.surfaceDark : AppColors.dividerLight;
        foregroundColor = isDark ? Colors.white : AppColors.textPrimaryLight;
        break;
      case BeityButtonType.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isDark ? AppColors.primaryLight : AppColors.primary;
        border = BorderSide(color: foregroundColor, width: 1.5);
        break;
      case BeityButtonType.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isDark ? AppColors.primaryLight : AppColors.primary;
        break;
    }

    // Disable colors if onPressed is null and not loading
    if (onPressed == null && !isLoading) {
      backgroundColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
      foregroundColor = isDark ? Colors.grey[600]! : Colors.grey[500]!;
      if (type == BeityButtonType.outline) {
        backgroundColor = Colors.transparent;
        border = BorderSide(color: foregroundColor, width: 1.5);
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
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
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
      overlayColor: WidgetStateProperty.all(foregroundColor.withOpacity(0.1)),
      padding: WidgetStateProperty.all(
        padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: border ?? BorderSide.none,
        ),
      ),
      elevation: WidgetStateProperty.all(type == BeityButtonType.primary && onPressed != null ? 2 : 0),
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

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
