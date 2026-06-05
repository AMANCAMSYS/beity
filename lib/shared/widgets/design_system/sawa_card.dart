import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

enum SawaCardVariant { elevated, outlined, interactive, compact }

class SawaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final SawaCardVariant variant;
  final bool hasBorder;
  final double? elevation;
  final BorderRadius? borderRadius;

  const SawaCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.variant = SawaCardVariant.outlined,
    this.hasBorder = false,
    this.elevation,
    this.borderRadius,
  });

  const SawaCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.hasBorder = false,
    this.elevation,
    this.borderRadius,
  }) : variant = SawaCardVariant.elevated;

  const SawaCard.interactive({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    required this.onTap,
    this.hasBorder = false,
    this.elevation,
    this.borderRadius,
  }) : variant = SawaCardVariant.interactive;

  const SawaCard.compact({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.hasBorder = false,
    this.elevation,
    this.borderRadius,
  }) : variant = SawaCardVariant.compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardPadding = padding ?? (variant == SawaCardVariant.compact
        ? const EdgeInsets.all(AppSpacing.sm)
        : const EdgeInsets.all(AppSpacing.md));
    final effectiveRadius = borderRadius ??
        BorderRadius.circular(
          variant == SawaCardVariant.compact ? AppSpacing.radiusMd : AppSpacing.radiusLg,
        );
    final effectiveElevation = elevation ?? (variant == SawaCardVariant.elevated ? 2 : 0);
    final showBorder = hasBorder || variant != SawaCardVariant.elevated;

    Widget cardContent = Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: effectiveRadius,
        border: showBorder
            ? Border.all(
                color: theme.colorScheme.outlineVariant,
                width: hasBorder ? 1.2 : 1,
              )
            : null,
        boxShadow: effectiveElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.08),
                  blurRadius: 8 + (effectiveElevation * 2),
                  offset: Offset(0, 1 + effectiveElevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null || variant == SawaCardVariant.interactive) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: cardContent);
    }

    return cardContent;
  }
}
