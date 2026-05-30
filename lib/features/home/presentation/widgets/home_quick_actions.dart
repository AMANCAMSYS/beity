import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/beity_card.dart';
import '../../../../shared/widgets/design_system/beity_snack_bar.dart';
import '../../../ai_suggestions/presentation/widgets/ai_list_selector_sheet.dart';
import '../../../onboarding/presentation/providers/app_tour_target_registry.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';

class HomeQuickActions extends ConsumerWidget {
  final String homeId;

  const HomeQuickActions({super.key, required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            key: AppTourTargetRegistry.quickAddKey,
            icon: Icons.add_shopping_cart_rounded,
            label: context.translate('add_item'),
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              final listsAsync = ref.read(shoppingListsProvider(homeId));
              listsAsync.whenData((lists) {
                if (lists.isNotEmpty) {
                  context.push('/shopping-list/${lists.first.id}/add-item');
                } else {
                  BeitySnackBar.warning(
                    context,
                    context.translate('must_create_list_first'),
                  );
                }
              });
            },
          ),
        ),
        AppSpacing.gapMD,
        Expanded(
          child: _buildActionCard(
            context,
            key: AppTourTargetRegistry.shoppingModeActionKey,
            icon: Icons.shopping_bag_rounded,
            label: context.translate('shopping_mode'),
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () {
              final listsAsync = ref.read(shoppingListsProvider(homeId));
              listsAsync.whenData((lists) {
                if (lists.isNotEmpty) {
                  context.push(
                    '/shopping-list/${lists.first.id}/shopping-mode',
                    extra: {
                      'homeId': lists.first.homeId,
                      'listName': lists.first.name,
                    },
                  );
                } else {
                  BeitySnackBar.warning(
                    context,
                    context.translate('no_lists_for_shopping_mode'),
                  );
                }
              });
            },
          ),
        ),
        if (FeatureFlags.enableAi) ...[
          AppSpacing.gapMD,
          Expanded(
            child: _buildActionCard(
              context,
              key: AppTourTargetRegistry.aiSuggestionsKey,
              icon: Icons.auto_awesome_rounded,
              label: context.translate('smart_suggestions'),
              color: AppColors.accent,
              onTap: () => AiListSelectorSheet.show(context, homeId),
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
    return BeityCard(
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
            ),
          ],
        ),
      ),
    );
  }
}
