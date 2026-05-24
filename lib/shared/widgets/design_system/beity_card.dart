import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

enum BeityCardVariant { elevated, outlined, interactive, compact }

class BeityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final BeityCardVariant variant;

  const BeityCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.variant = BeityCardVariant.outlined,
  });

  const BeityCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
  }) : variant = BeityCardVariant.elevated;

  const BeityCard.interactive({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    required this.onTap,
  }) : variant = BeityCardVariant.interactive;

  const BeityCard.compact({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
  }) : variant = BeityCardVariant.compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPadding = padding ?? (variant == BeityCardVariant.compact
        ? const EdgeInsets.all(AppSpacing.sm)
        : const EdgeInsets.all(AppSpacing.md));

    Widget cardContent = Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(
          variant == BeityCardVariant.compact ? AppSpacing.radiusMd : AppSpacing.radiusLg,
        ),
        border: variant == BeityCardVariant.elevated
            ? null
            : Border.all(
                color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                width: 1,
              ),
        boxShadow: variant == BeityCardVariant.elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null || variant == BeityCardVariant.interactive) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            variant == BeityCardVariant.compact ? AppSpacing.radiusMd : AppSpacing.radiusLg,
          ),
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
