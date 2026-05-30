import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/features/onboarding/presentation/providers/app_tour_target_registry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = [
      _ShellNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: context.translate('home_tab'),
      ),
      _ShellNavDestination(
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt_rounded,
        label: context.translate('lists_tab'),
      ),
      _ShellNavDestination(
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart_rounded,
        label: context.translate('shopping_tab'),
      ),
      _ShellNavDestination(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history_rounded,
        label: context.translate('activity_tab'),
      ),
      _ShellNavDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: context.translate('settings_tab'),
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.98),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 76,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.55 : 0.85,
                  ),
                ),
              ),
            ),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _ShellNavItem(
                      key: _navKeyFor(index),
                      destination: items[index],
                      isSelected: navigationShell.currentIndex == index,
                      onTap: () => _onTap(context, index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// Maps branch index → tour GlobalKey (only for targeted tabs).
  static GlobalKey? _navKeyFor(int index) {
    switch (index) {
      case 1:
        return AppTourTargetRegistry.listsTabKey;
      case 2:
        return AppTourTargetRegistry.shoppingTabKey;
      case 3:
        return AppTourTargetRegistry.activityTabKey;
      default:
        return null;
    }
  }
}

class _ShellNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _ShellNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _ShellNavItem extends StatelessWidget {
  final _ShellNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShellNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: destination.label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: destination.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.5
                              : 0.9,
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 24 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? destination.selectedIcon
                                : destination.icon,
                            size: 23,
                            color: isSelected ? selectedColor : unselectedColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? selectedColor
                                  : unselectedColor,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
