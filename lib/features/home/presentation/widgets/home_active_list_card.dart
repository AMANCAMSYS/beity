import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/shopping_route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/shopping_ui_utils.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';

class HomeActiveListCard extends ConsumerWidget {
  final ShoppingListModel activeList;

  const HomeActiveListCard({super.key, required this.activeList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(shoppingListSummariesProvider(activeList.homeId));

    return summariesAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (summaries) {
        final summary = summaries[activeList.id] ?? ShoppingListSummary(total: 0, purchased: 0);
        final total = summary.total;
        final remaining = summary.remaining;
        final progress = summary.progress;

        return SawaCard(
          onTap: () => context.push(ShoppingRoutePaths.detail(activeList.id)),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Icon(
                        ShoppingUiUtils.getIconData(activeList.icon),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            total == 0
                                ? context.translate('list_empty')
                                : context.translate(
                                    'items_remaining_count',
                                    arguments: {
                                      'remaining': remaining.toString(),
                                      'total': total.toString(),
                                    },
                                  ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                          color: ShoppingUiUtils.getProgressColor(
                            progress,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: ShoppingUiUtils.getProgressColor(progress),
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
                      backgroundColor: ShoppingUiUtils.getProgressColor(
                        progress,
                      ).withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ShoppingUiUtils.getProgressColor(progress),
                      ),
                    ),
                  ),
                ],
                // Action buttons
                AppSpacing.gapLG,
                Row(
                  children: [
                    Expanded(
                      child: SawaButton(
                        onPressed: () => context.push(
                          ShoppingRoutePaths.detail(activeList.id),
                        ),
                        text: context.translate('open_list'),
                        type: SawaButtonType.secondary,
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    AppSpacing.gapMD,
                    Expanded(
                      child: SawaButton(
                        onPressed: () {
                          context.push(
                            ShoppingRoutePaths.shoppingMode(activeList.id),
                            extra: {
                              'homeId': activeList.homeId,
                              'listName': activeList.name,
                            },
                          );
                        },
                        text: context.translate('shopping_mode'),
                        type: SawaButtonType.primary,
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
      loading: () => const SawaCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
