import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/permissions_provider.dart';

import 'package:sawa/app/router/shopping_route_paths.dart';
import 'package:sawa/app/router/feature_route_paths.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../home/presentation/widgets/app_drawer.dart';
import '../../../home/presentation/widgets/drawer_toggle_button.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/domain/usecases/add_purchased_to_inventory_usecase.dart';
import '../providers/shopping_lists_provider.dart';
import '../widgets/shopping_list_card_widget.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/archive_list_usecase.dart';
import '../../domain/usecases/delete_list_usecase.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../core/config/feature_flags.dart';
import 'package:sawa/features/ai_suggestions/presentation/widgets/ai_list_selector_sheet.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../../../core/errors/error_formatter.dart';

class ShoppingListsScreen extends ConsumerStatefulWidget {
  final String homeId;

  const ShoppingListsScreen({super.key, required this.homeId});

  @override
  ConsumerState<ShoppingListsScreen> createState() =>
      _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends ConsumerState<ShoppingListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final homeId = widget.homeId.isNotEmpty
        ? widget.homeId
        : ref.watch(cachedActiveHomeIdProvider) ?? '';

    if (homeId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final listsAsync = ref.watch(shoppingListsProvider(homeId));
    final activeLists = ref.watch(activeShoppingListsProvider(homeId));
    final completedLists = ref.watch(completedShoppingListsProvider(homeId));
    final archivedLists = ref.watch(archivedShoppingListsProvider(homeId));
    final permissions = ref.watch(currentHomePermissionsProvider(homeId));
    final canManage = permissions.canEdit;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leadingWidth: 62,
        leading: Builder(builder: (context) => const DrawerToggleButton()),
        title: Text(context.translate('shopping_lists')),
        centerTitle: true,
        actions: [
          if (FeatureFlags.enableAi)
            IconButton(
              icon: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
              ),
              onPressed: () => AiListSelectorSheet.show(context, homeId),
              tooltip: context.translate('ai_assistant'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall,
          tabs: [
            Tab(
              text: context.translate(
                'active_lists_count',
                arguments: {'count': activeLists.length.toString()},
              ),
            ),
            Tab(
              text: context.translate(
                'completed_lists_count',
                arguments: {'count': completedLists.length.toString()},
              ),
            ),
            Tab(
              text: context.translate(
                'archived_lists_count',
                arguments: {'count': archivedLists.length.toString()},
              ),
            ),
          ],
        ),
      ),
      body: listsAsync.when(
        skipLoadingOnReload: true,
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _buildListsList(activeLists, homeId: homeId),
            _buildListsList(completedLists, homeId: homeId, isCompleted: true),
            _buildListsList(archivedLists, homeId: homeId, isArchived: true),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => SawaEmptyState(
          title: context.translate('error_loading_lists'),
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(shoppingListsProvider(homeId)),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => ActionDebouncer.execute(
                () => context.push(ShoppingRoutePaths.create, extra: homeId),
              ),
              label: Text(context.translate('new_list')),
              icon: const Icon(Icons.add_rounded),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildListsList(
    List<ShoppingList> lists, {
    required String homeId,
    bool isArchived = false,
    bool isCompleted = false,
  }) {
    final theme = Theme.of(context);
    final permissions = ref.watch(currentHomePermissionsProvider(homeId));
    final canManage = permissions.canEdit;

    if (lists.isEmpty) {
      return SawaEmptyState(
        title: isCompleted
            ? context.translate('no_completed_lists')
            : isArchived
            ? context.translate('no_archived_lists')
            : context.translate('no_shopping_lists'),
        message: isCompleted
            ? context.translate('no_completed_lists_desc')
            : isArchived
            ? context.translate('no_archived_lists_desc')
            : context.translate('no_shopping_lists_desc'),
        icon: isCompleted
            ? Icons.task_alt_rounded
            : isArchived
            ? Icons.archive_outlined
            : Icons.shopping_bag_outlined,
        actionText: (!isArchived && !isCompleted && canManage)
            ? context.translate('create_first_list')
            : null,
        onAction: (!isArchived && !isCompleted && canManage)
            ? () => ActionDebouncer.execute(
                () => context.push(ShoppingRoutePaths.create, extra: homeId),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(shoppingListsProvider(homeId)),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: lists.length,
        itemBuilder: (context, index) {
          final list = lists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ShoppingListCardWidget(
              shoppingList: list,
              onTap: () => ActionDebouncer.execute(
                () async => context.push(ShoppingRoutePaths.detail(list.id)),
              ),
              onRename: (isArchived || !canManage)
                  ? null
                  : () => ActionDebouncer.execute(
                      () async => _showRenameDialog(context, list),
                    ),
              onArchive: (isArchived || isCompleted || !canManage)
                  ? null
                  : () =>
                        ActionDebouncer.execute(() async => _archiveList(list)),
              onDelete: !canManage
                  ? null
                  : () => ActionDebouncer.execute(
                      () async => _showDeleteConfirmation(context, list),
                    ),
              onRestore: (isArchived && canManage)
                  ? () =>
                        ActionDebouncer.execute(() async => _restoreList(list))
                  : null,
              onTransferToInventory:
                  (FeatureFlags.enableInventory &&
                      isCompleted &&
                      canManage &&
                      list.canTransferToInventory)
                  ? () => ActionDebouncer.execute(
                      () async => _transferListToInventory(context, list),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ShoppingList list) {
    final nameController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.translate('rename_list'),
          textAlign: TextAlign.center,
        ),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        content: SawaTextField(
          controller: nameController,
          labelText: context.translate('new_list_name'),
          prefixIcon: Icons.edit_rounded,
          autofocus: true,
          onSubmitted: (_) => ActionDebouncer.execute(
            () => _performRename(dialogContext, list, nameController),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SawaButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  text: context.translate('cancel'),
                  type: SawaButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: SawaButton(
                  onPressed: () => ActionDebouncer.execute(
                    () => _performRename(dialogContext, list, nameController),
                  ),
                  text: context.translate('save'),
                  type: SawaButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performRename(
    BuildContext context,
    ShoppingList list,
    TextEditingController controller,
  ) async {
    if (controller.text.trim().isNotEmpty) {
      try {
        final repository = ref.read(
          shoppingListRepositoryForHomeProvider(list.homeId),
        );
        await repository.updateShoppingList(
          listId: list.id,
          name: controller.text.trim(),
        );
        ref.invalidate(shoppingListsProvider(list.homeId));
        if (context.mounted) {
          Navigator.pop(context);
          SawaSnackBar.success(
            context,
            context.translate('list_renamed_success'),
          );
        }
      } catch (e) {
        if (context.mounted) {
          SawaSnackBar.error(context, ErrorFormatter.format(e, context));
        }
      }
    }
  }

  Future<void> _archiveList(ShoppingList list) async {
    try {
      final repository = ref.read(
        shoppingListRepositoryForHomeProvider(list.homeId),
      );
      final useCase = ArchiveListUseCase(repository);
      await useCase(listId: list.id);
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
    }
  }

  Future<void> _restoreList(ShoppingList list) async {
    try {
      final repository = ref.read(
        shoppingListRepositoryForHomeProvider(list.homeId),
      );
      final useCase = ArchiveListUseCase(repository);
      await useCase.restore(listId: list.id);
      if (mounted) {
        SawaSnackBar.success(
          context,
          context.translate('list_restored_success'),
        );
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
      }
    }
  }

  Future<void> _transferListToInventory(
    BuildContext context,
    ShoppingList list,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = ref.read(
        shoppingListRepositoryForHomeProvider(list.homeId),
      );
      final items = await repository.getShoppingItems(listId: list.id);

      if (!context.mounted) return;

      final purchasedItems = items
          .where((i) => i.isPurchased || i.purchasedQuantity > 0)
          .toList();

      if (purchasedItems.isEmpty) {
        Navigator.pop(context);
        SawaSnackBar.error(context, context.translate('no_purchased_items'));
        return;
      }

      final inventoryUseCase = ref.read(addPurchasedToInventoryUseCaseProvider);
      final inputs = purchasedItems
          .map(
            (item) => PurchasedItemInput(
              name: item.name,
              quantity: item.purchasedQuantity > 0
                  ? item.purchasedQuantity
                  : item.quantity,
              unitId: item.unitId,
              categoryId: item.categoryId,
            ),
          )
          .toList();

      await inventoryUseCase.callBatch(
        listId: list.id,
        homeId: list.homeId,
        items: inputs,
      );

      if (!context.mounted) return;

      Navigator.pop(context);
      ref.invalidate(shoppingListsProvider(list.homeId));

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.translate(
                    'added_to_inventory_success',
                    arguments: {'count': purchasedItems.length.toString()},
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: context.translate('view_inventory'),
            textColor: Colors.white,
            onPressed: () => context.push(FeatureRoutePaths.inventory),
          ),
        ),
      );
    } catch (e) {
      await MonitoringService().log('Failed to transfer list to inventory: $e');
      if (!context.mounted) return;
      Navigator.pop(context);
      SawaSnackBar.error(context, ErrorFormatter.format(e, context));
    }
  }

  void _showDeleteConfirmation(BuildContext context, ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.translate('delete_list'),
          textAlign: TextAlign.center,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.error,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        content: Text(
          context.translate(
            'delete_list_confirm_msg',
            arguments: {'name': list.name},
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SawaButton(
                  onPressed: () => Navigator.pop(context),
                  text: context.translate('cancel'),
                  type: SawaButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: SawaButton(
                  onPressed: () => ActionDebouncer.execute(() async {
                    try {
                      final repository = ref.read(
                        shoppingListRepositoryForHomeProvider(list.homeId),
                      );
                      final useCase = DeleteListUseCase(repository);
                      await useCase(listId: list.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        SawaSnackBar.success(
                          context,
                          context.translate('list_deleted_success'),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        SawaSnackBar.error(context, ErrorFormatter.format(e, context));
                      }
                    }
                  }),
                  text: context.translate('delete'),
                  type: SawaButtonType.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
