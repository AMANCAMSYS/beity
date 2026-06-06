import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../domain/entities/ai_mode.dart';
import '../../../../app/theme/app_colors.dart';

enum AiPortal {
  shopping,
  cooking,
  occasions;

  String get translationKey {
    return switch (this) {
      AiPortal.shopping => 'portal_shopping',
      AiPortal.cooking => 'portal_cooking',
      AiPortal.occasions => 'portal_occasions',
    };
  }

  IconData get icon {
    return switch (this) {
      AiPortal.shopping => Icons.shopping_bag_rounded,
      AiPortal.cooking => Icons.restaurant_menu_rounded,
      AiPortal.occasions => Icons.celebration_rounded,
    };
  }

  List<AiMode> get subModes {
    return switch (this) {
      AiPortal.shopping => [
        AiMode.shoppingSuggestions,
        AiMode.ramadanList,
        AiMode.travelList,
        AiMode.cleaningList,
      ],
      AiPortal.cooking => [
        AiMode.whatToCook,
        AiMode.recipeIngredients,
        AiMode.cookByAvailable,
        AiMode.weeklyMealPlan,
        AiMode.quickMeals,
        AiMode.healthyMeals,
        AiMode.budgetMeals,
        AiMode.cookByVegetables,
        AiMode.cookBySpices,
      ],
      AiPortal.occasions => [AiMode.guestMeals, AiMode.kidsMeals],
    };
  }

  AiMode get defaultMode {
    return switch (this) {
      AiPortal.shopping => AiMode.shoppingSuggestions,
      AiPortal.cooking => AiMode.whatToCook,
      AiPortal.occasions => AiMode.guestMeals,
    };
  }
}

/// Simplified 3-portal AI mode selector.
class AiModeSelector extends StatefulWidget {
  final AiMode selectedMode;
  final ValueChanged<AiMode> onModeChanged;

  const AiModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  State<AiModeSelector> createState() => _AiModeSelectorState();
}

class _AiModeSelectorState extends State<AiModeSelector> {
  late AiPortal _activePortal;

  @override
  void initState() {
    super.initState();
    _activePortal = _getPortalForMode(widget.selectedMode);
  }

  @override
  void didUpdateWidget(covariant AiModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMode != widget.selectedMode) {
      setState(() {
        _activePortal = _getPortalForMode(widget.selectedMode);
      });
    }
  }

  AiPortal _getPortalForMode(AiMode mode) {
    for (final portal in AiPortal.values) {
      if (portal.subModes.contains(mode)) {
        return portal;
      }
    }
    return AiPortal.cooking;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. PORTALS ROW ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final portal in AiPortal.values) ...[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activePortal = portal;
                      });
                      widget.onModeChanged(portal.defaultMode);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _activePortal == portal
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : (isDark
                                  ? AppColors.surfaceDark
                                  : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _activePortal == portal
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            portal.icon,
                            color: _activePortal == portal
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.translate(portal.translationKey),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: _activePortal == portal
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _activePortal == portal
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (portal != AiPortal.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 2. SUB-MODES SCROLLABLE ROW ──
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: _activePortal.subModes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final mode = _activePortal.subModes[index];
              final isSelected = mode == widget.selectedMode;

              return GestureDetector(
                onTap: () => widget.onModeChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark
                              ? AppColors.surfaceDark
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.translate(mode.translationKey),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
