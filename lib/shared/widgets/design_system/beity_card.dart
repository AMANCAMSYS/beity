import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class BeityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;
  final bool hasBorder;
  final BorderRadiusGeometry? borderRadius;

  const BeityCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.onTap,
    this.hasBorder = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBackgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final defaultBorderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
        border: hasBorder ? Border.all(color: defaultBorderColor, width: 1.0) : null,
        boxShadow: (elevation ?? (hasBorder ? 0 : 2)) > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: elevation ?? 2,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: (borderRadius as BorderRadius?) ?? BorderRadius.circular(AppSpacing.radiusLg),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
