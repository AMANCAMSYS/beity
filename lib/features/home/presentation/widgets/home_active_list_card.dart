import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/beity_card.dart';
import '../../../../shared/widgets/design_system/beity_button.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';

class HomeActiveListCard extends ConsumerWidget {
  final ShoppingListModel activeList;

  const HomeActiveListCard({super.key, required this.activeList});

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.success;
    if (progress >= 0.5) return AppColors.info;
    if (progress >= 0.3) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'local_grocery_store':
        return Icons.local_grocery_store_rounded;
      case 'local_pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'local_hospital':
        return Icons.local_hospital_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'hardware':
        return Icons.hardware_rounded;
      case 'build':
        return Icons.build_rounded;
      case 'child_care':
        return Icons.child_care_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'local_florist':
        return Icons.local_florist_rounded;
      default:
        return Icons.shopping_cart_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider(activeList.id));

    return itemsAsync.when(
      data: (items) {
        final total = items.length;
        final purchased = items.where((i) => i.isPurchased).length;
        final remaining = total - purchased;
        final progress = total > 0 ? purchased / total : 0.0;

        return BeityCard(
          onTap: () => context.push('/shopping-list/${activeList.id}'),
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Icon(
                        _getIconData(activeList.icon),
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    AppSpacing.gapLG,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeList.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            total == 0
                                ? context.translate('list_empty')
                                : context.translate('items_remaining_count',
                                    arguments: {
                                        'remaining': remaining.toString(),
                                        'total': total.toString(),
                                      }),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Progress chip
                    if (total > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getProgressColor(
                            progress,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: _getProgressColor(progress),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                // Progress bar
                if (total > 0) ...[
                  AppSpacing.gapLG,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: _getProgressColor(
                        progress,
                      ).withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                ],
                // Action buttons
                AppSpacing.gapLG,
                Row(
                  children: [
                    Expanded(
                      child: BeityButton(
                        onPressed: () =>
                            context.push('/shopping-list/${activeList.id}'),
                        text: context.translate('open_list'),
                        type: BeityButtonType.secondary,
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    AppSpacing.gapMD,
                    Expanded(
                      child: BeityButton(
                        onPressed: () {
                          context.push(
                            '/shopping-list/${activeList.id}/shopping-mode',
                            extra: {
                              'homeId': activeList.homeId,
                              'listName': activeList.name,
                            },
                          );
                        },
                        text: context.translate('shopping_mode'),
                        type: BeityButtonType.primary,
                        icon: Icons.shopping_bag_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const BeityCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
