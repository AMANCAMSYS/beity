import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/shopping_route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/design_system/sawa_empty_state.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../home/presentation/widgets/app_drawer.dart';
import '../../../home/presentation/widgets/drawer_toggle_button.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';

class ShoppingModeListScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ShoppingModeListScreen({super.key, required this.homeId});

  @override
  ConsumerState<ShoppingModeListScreen> createState() =>
      _ShoppingModeListScreenState();
}

class _ShoppingModeListScreenState
    extends ConsumerState<ShoppingModeListScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listsAsync = ref.watch(shoppingListsProvider(widget.homeId));
    final activeLists = ref.watch(activeShoppingListsProvider(widget.homeId));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leadingWidth: 62,
        leading: Builder(builder: (context) => const DrawerToggleButton()),
        title: Text(
          context.translate('shopping_mode'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: listsAsync.when(
        skipLoadingOnReload: true,
        data: (_) => activeLists.isEmpty
            ? SawaEmptyState(
                title: context.translate('no_active_lists'),
                message: context.translate(
                  'no_active_lists_desc_shopping_mode',
                ),
                icon: Icons.playlist_add_rounded,
                actionText: context.translate('create_list'),
                onAction: () => ActionDebouncer.execute(
                  () async => context.go(ShoppingRoutePaths.lists),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.translate('shopping_mode_title_instructions'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.translate(
                            'shopping_mode_subtitle_instructions',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...activeLists.map(
                    (list) => _buildShoppingListCard(context, ref, list),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => SawaEmptyState(
          title: context.translate('error_loading_lists'),
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(shoppingListsProvider(widget.homeId)),
        ),
      ),
    );
  }

  Widget _buildShoppingListCard(
    BuildContext context,
    WidgetRef ref,
    ShoppingListModel list,
  ) {
    final theme = Theme.of(context);

    // Listen to shopping items for real-time progress
    final itemsAsync = ref.watch(
      shoppingItemsForHomeProvider((listId: list.id, homeId: list.homeId)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SawaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                AppSpacing.gapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (list.description != null &&
                          list.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          list.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapLG,
            itemsAsync.when(
              data: (items) {
                final totalItems = items.length;
                final purchasedItems = items.where((i) => i.isPurchased).length;
                final progress = totalItems == 0
                    ? 0.0
                    : purchasedItems / totalItems;
                final progressPercentage = (progress * 100).toInt();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.translate(
                            'shopping_progress_label',
                            arguments: {
                              'purchased': purchasedItems.toString(),
                              'total': totalItems.toString(),
                            },
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$progressPercentage%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0
                              ? AppColors.success
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    AppSpacing.gapLG,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            totalItems == 0 || purchasedItems == totalItems
                            ? null
                            : () => ActionDebouncer.execute(() async {
                                context.push(
                                  ShoppingRoutePaths.shoppingMode(list.id),
                                  extra: {
                                    'homeId': list.homeId,
                                    'listName': list.name,
                                  },
                                );
                              }),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          context.translate('start_shopping'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, s) => Text(context.translate('load_items_failed')),
            ),
          ],
        ),
      ),
    );
  }
}
