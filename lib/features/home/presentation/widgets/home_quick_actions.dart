import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/feature_route_paths.dart';
import '../../../../app/router/shopping_route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';

class HomeQuickActions extends StatelessWidget {
  final String homeId;

  const HomeQuickActions({super.key, required this.homeId});

  @override
  Widget build(BuildContext context) {
    final actions = <_HomeShortcutAction>[
      if (FeatureFlags.enableInventory)
        _HomeShortcutAction(
          icon: Icons.inventory_2_rounded,
          label: context.translate('inventory'),
          color: Theme.of(context).colorScheme.primary,
          onTap: () => context.push(FeatureRoutePaths.inventory, extra: homeId),
        ),
      if (FeatureFlags.enableExpenses)
        _HomeShortcutAction(
          icon: Icons.receipt_long_rounded,
          label: context.translate('expenses'),
          color: Theme.of(context).colorScheme.tertiary,
          onTap: () => context.push(FeatureRoutePaths.expenses, extra: homeId),
        ),
      if (FeatureFlags.enableTasks)
        _HomeShortcutAction(
          icon: Icons.task_alt_rounded,
          label: context.translate('tasks'),
          color: Theme.of(context).colorScheme.secondary,
          onTap: () => context.push(FeatureRoutePaths.tasks(homeId)),
        ),
    ];

    if (actions.isEmpty) {
      actions.add(
        _HomeShortcutAction(
          icon: Icons.list_alt_rounded,
          label: context.translate('shopping_lists'),
          color: Theme.of(context).colorScheme.primary,
          onTap: () => context.go(ShoppingRoutePaths.lists, extra: homeId),
        ),
      );
    }

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) AppSpacing.gapMD,
          Expanded(
            child: _buildActionCard(
              context,
              icon: actions[index].icon,
              label: actions[index].label,
              color: actions[index].color,
              onTap: actions[index].onTap,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SawaCard(
      key: key,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            AppSpacing.gapSM,
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeShortcutAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HomeShortcutAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
