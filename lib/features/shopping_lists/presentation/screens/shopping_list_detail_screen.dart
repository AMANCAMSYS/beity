import 'dart:async';
import 'package:beity/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../providers/realtime_providers.dart';
import '../widgets/quick_add_item_bottom_sheet.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/presence_indicator_widget.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/list_detail_search_bar.dart';
import '../widgets/list_detail_summary_bar.dart';
import '../widgets/list_detail_category_section.dart';
import '../widgets/shopping_item_tile_widget.dart';
import '../../domain/usecases/mark_item_purchased_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../data/models/shopping_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../offline_queue/presentation/widgets/connectivity_listener.dart';
import '../../../offline_queue/presentation/widgets/sync_status_banner.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../offline_queue/presentation/providers/connectivity_provider.dart';
import '../../../offline_queue/domain/entities/sync_status.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../core/localization/app_localizations.dart';

enum _ListAction { shoppingMode, summary, activity, quickAdd }

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ShoppingListDetailScreen({super.key, required this.listId});

  @override
  ConsumerState<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState
    extends ConsumerState<ShoppingListDetailScreen> {
  // Undo delete state
  ShoppingItemModel? _lastDeletedItem;
  Timer? _undoTimer;

  // Search/filter state
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategoryId;

  // Category expansion state
  final Map<String?, bool> _expandedCategories = {};

  // Conflict highlight state
  final Map<String, DateTime> _highlightedItems = {};

  @override
  void initState() {
    super.initState();
    _joinPresence();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _searchController.dispose();
    _leavePresence();
    super.dispose();
  }

  void _joinPresence() {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final service = ref.read(realtimeServiceProvider);
      if (service.isDisposed) return;
      final channelName = 'presence:list:${widget.listId}';
      service.watchPresence(
        channelName: channelName,
        userPayload: PresencePayload(
          userId: currentUser.id,
          displayName:
              currentUser.userMetadata?['full_name'] as String? ??
                  ref.read(appLocalizationsProvider).translate('user'),
          avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
        ),
      );
    } catch (_) {}
  }

  void _leavePresence() {
    try {
      final service = ref.read(realtimeServiceProvider);
      if (!service.isDisposed) {
        final channelName = 'presence:list:${widget.listId}';
        service.leavePresence(channelName: channelName);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));
    final itemsAsync = ref.watch(shoppingItemsProvider(widget.listId));
    final connectionState = ref.watch(connectionStateProvider);
    final currentUser = SupabaseService.client.auth.currentUser;
    final settings = ref.watch(appSettingsProvider);

    final list = listAsync.valueOrNull;
    final homeId = list?.homeId ?? '';
    final presenceAsync = ref.watch(presenceProvider(widget.listId));

    // Load units for display
    final unitsAsync = ref.watch(unitsProvider(null));
    final unitNames = <String, String>{};
    unitsAsync.whenData((units) {
      for (final unit in units) {
        unitNames[unit.id] = unit.symbol.isNotEmpty
            ? '${unit.name} (${unit.symbol})'
            : unit.name;
      }
    });

    // Load categories for filter
    final categoriesAsync = ref.watch(categoriesProvider(homeId));

    // Offline queue status
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final isOffline = connectivityStatus.valueOrNull?.isOffline ?? false;
    final canSyncNow = ref.watch(canSyncNowProvider);
    final pendingCount = homeId.isNotEmpty
        ? ref.watch(pendingCountProvider(homeId)).valueOrNull ?? 0
        : 0;
    final failedCount = homeId.isNotEmpty
        ? ref.watch(failedCountProvider(homeId)).valueOrNull ?? 0
        : 0;

    return ConnectivityListener(
      homeId: homeId,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const BackButtonIcon(),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/shopping-lists');
              }
            },
            tooltip: context.translate('back'),
          ),
          title: listAsync.when(
            data: (list) => Text(
              list?.name ?? context.translate('shopping_lists'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            loading: () => Text(context.translate('loading')),
            error: (error, stackTrace) =>
                Text(context.translate('error_title')),
          ),
          actions: [
            if (FeatureFlags.enableAi)
              IconButton(
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accent,
                ),
                onPressed: () => ActionDebouncer.execute(() async {
                  final list = listAsync.valueOrNull;
                  if (list != null) {
                    final existingItemNames =
                        itemsAsync.valueOrNull?.map((e) => e.name).toList() ??
                        [];
                    context.push(
                      '/shopping-list/${widget.listId}/ai-suggestions',
                      extra: {
                        'listId': list.id,
                        'listTitle': list.name,
                        'homeId': list.homeId,
                        'homeType': 'family',
                        'existingItemNames': existingItemNames,
                      },
                    );
                  }
                }),
                tooltip: context.translate('smart_suggestions'),
              ),
            IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
              ),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
              tooltip: context.translate('search'),
            ),
            PopupMenuButton<_ListAction>(
              tooltip: context.translate('more'),
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (action) {
                switch (action) {
                  case _ListAction.shoppingMode:
                    ActionDebouncer.execute(() async {
                      final list = listAsync.valueOrNull;
                      if (list != null) {
                        context.push(
                          '/shopping-list/${widget.listId}/shopping-mode',
                          extra: {'homeId': list.homeId, 'listName': list.name},
                        );
                      }
                    });
                    break;
                  case _ListAction.summary:
                    ActionDebouncer.execute(
                      () => context.push(
                        '/shopping-list/${widget.listId}/summary',
                      ),
                    );
                    break;
                  case _ListAction.activity:
                    ActionDebouncer.execute(
                      () => context.push(
                        '/shopping-list/${widget.listId}/activity',
                        extra: {
                          'homeId': list?.homeId ?? '',
                          'listName':
                              list?.name ?? context.translate('shopping_lists'),
                        },
                      ),
                    );
                    break;
                  case _ListAction.quickAdd:
                    ActionDebouncer.execute(
                      () => context.push(
                        '/shopping-list/${widget.listId}/quick-add',
                        extra: list?.homeId ?? '',
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ListAction.shoppingMode,
                  child: ListTile(
                    leading: const Icon(Icons.shopping_cart_rounded),
                    title: Text(context.translate('start_shopping')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _ListAction.summary,
                  child: ListTile(
                    leading: const Icon(Icons.summarize_rounded),
                    title: Text(context.translate('list_summary')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _ListAction.activity,
                  child: ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(context.translate('activity_log')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _ListAction.quickAdd,
                  child: ListTile(
                    leading: const Icon(Icons.bolt_rounded),
                    title: Text(context.translate('quick_add')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            SyncStatusBanner(
              pendingCount: pendingCount,
              failedCount: failedCount,
              isOffline: isOffline,
              canSyncNow: canSyncNow,
              onRetryAll: () => _retryFailedEntries(homeId),
            ),
            // Connection status
            connectionState.when(
              data: (state) => ConnectionStatusWidget(connectionState: state),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            // Presence indicators
            presenceAsync.when(
              data: (presences) => PresenceIndicatorWidget(
                presences: presences,
                currentUserId: currentUser?.id ?? '',
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            // Main content
            Expanded(
              child: listAsync.when(
                data: (list) {
                  if (list == null) {
                    return BeityEmptyState(
                      title: context.translate('list_not_found'),
                      message: context.translate('list_not_found_desc'),
                      icon: Icons.error_outline_rounded,
                      isError: true,
                      actionText: context.translate('back_to_lists'),
                      onAction: () => ActionDebouncer.execute(
                        () async => context.go('/shopping-lists'),
                      ),
                    );
                  }

                  return itemsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return BeityEmptyState(
                          title: context.translate('list_empty'),
                          message: context.translate('list_empty_desc'),
                          icon: Icons.shopping_basket_rounded,
                          actionText: context.translate('add_first_item'),
                          onAction: () => ActionDebouncer.execute(() async {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => QuickAddItemBottomSheet(
                                listId: widget.listId,
                                homeId: homeId,
                              ),
                            );
                          }),
                        );
                      }

                      var filtered = items;
                      if (_searchQuery.isNotEmpty) {
                        filtered = filtered
                            .where(
                              (i) => i.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();
                      }

                      if (_filterCategoryId != null) {
                        filtered = filtered
                            .where((i) => i.categoryId == _filterCategoryId)
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return BeityEmptyState(
                          title: context.translate('no_results'),
                          message: context.translate('no_results_desc'),
                          icon: Icons.search_off_rounded,
                          actionText: context.translate('clear_filters'),
                          onAction: () {
                            setState(() {
                              _searchQuery = '';
                              _filterCategoryId = null;
                              _searchController.clear();
                            });
                          },
                        );
                      }

                      final grouped = <String?, List<ShoppingItemModel>>{};
                      if (settings.groupedByCategory) {
                        for (final item in filtered) {
                          grouped
                              .putIfAbsent(item.categoryId, () => [])
                              .add(item);
                        }
                        for (final group in grouped.values) {
                          group.sort((a, b) {
                            if (a.isPurchased == b.isPurchased) return 0;
                            return a.isPurchased ? 1 : -1;
                          });
                        }
                      } else {
                        filtered.sort((a, b) {
                          if (a.isPurchased == b.isPurchased) return 0;
                          return a.isPurchased ? 1 : -1;
                        });
                      }
                      final unpurchasedTotal = items
                          .where((i) => !i.isPurchased && i.price != null)
                          .fold<double>(0, (sum, i) => sum + i.price!);

                      return Column(
                        children: [
                          if (_isSearchVisible)
                            ListDetailSearchBar(
                              controller: _searchController,
                              searchQuery: _searchQuery,
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                              onClear: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          categoriesAsync.when(
                            data: (categories) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: CategoryFilterWidget(
                                categories: categories,
                                selectedCategoryId: _filterCategoryId,
                                onCategorySelected: (id) {
                                  setState(() => _filterCategoryId = id);
                                },
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              children: [
                                if (settings.groupedByCategory)
                                  ...grouped.entries.map((entry) {
                                    final categoryId = entry.key;
                                    final groupItems = entry.value;
                                    final isExpanded =
                                        _expandedCategories[categoryId] ?? true;

                                    return ListDetailCategorySection(
                                      categoryId: categoryId,
                                      items: groupItems,
                                      isExpanded: isExpanded,
                                      homeId: homeId,
                                      unitNames: unitNames,
                                      listId: widget.listId,
                                      highlightedItems: _highlightedItems,
                                      isCompact: settings.compactListMode,
                                      hapticsEnabled: settings.hapticFeedback,
                                      soundsEnabled: settings.soundEffects,
                                      onExpansionChanged: (expanded) {
                                        setState(() {
                                          _expandedCategories[categoryId] = expanded;
                                        });
                                      },
                                      onTogglePurchased: _togglePurchased,
                                      onDelete: _deleteItem,
                                    );
                                  })
                                else
                                  ...filtered.map((item) {
                                    final queueEntries = ref.watch(queueEntriesProvider(homeId));
                                    final hasPending = queueEntries.when(
                                      data: (entries) =>
                                          entries.any((e) => e.entityId == item.id && e.isPending),
                                      loading: () => false,
                                      error: (error, stackTrace) => false,
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                      child: ShoppingItemTileWidget(
                                        item: item,
                                        unitName: item.unitId != null ? unitNames[item.unitId] : null,
                                        highlightUntil: _highlightedItems[item.id],
                                        showPendingIndicator: hasPending,
                                        isCompact: settings.compactListMode,
                                        hapticsEnabled: settings.hapticFeedback,
                                        soundsEnabled: settings.soundEffects,
                                        onTogglePurchased: () => ActionDebouncer.execute(
                                          () => _togglePurchased(item.id, !item.isPurchased),
                                        ),
                                        onEdit: () => ActionDebouncer.execute(
                                          () => context.push(
                                            '/shopping-list/${widget.listId}/edit-item/${item.id}',
                                          ),
                                        ),
                                        onDelete: () => ActionDebouncer.execute(() => _deleteItem(item)),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ),
                          ),
                          ListDetailSummaryBar(
                            listId: widget.listId,
                            homeId: homeId,
                            unpurchasedTotal: unpurchasedTotal,
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => BeityEmptyState(
                      title: context.translate('load_items_failed'),
                      message: error.toString(),
                      icon: Icons.error_outline_rounded,
                      isError: true,
                      actionText: context.translate('retry'),
                      onAction: () =>
                          ref.invalidate(shoppingItemsProvider(widget.listId)),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => BeityEmptyState(
                  title: context.translate('load_list_failed'),
                  message: error.toString(),
                  icon: Icons.error_outline_rounded,
                  isError: true,
                  actionText: context.translate('retry'),
                  onAction: () =>
                      ref.invalidate(shoppingListByIdProvider(widget.listId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePurchased(String itemId, bool isPurchased) async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = MarkItemPurchasedUseCase(repository);
    await useCase(itemId: itemId, isPurchased: isPurchased);
  }

  Future<void> _deleteItem(ShoppingItemModel item) async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = DeleteItemUseCase(repository);

    final deletedItem = await useCase.callAndReturn(itemId: item.id);

    if (mounted && deletedItem != null) {
      setState(() => _lastDeletedItem = deletedItem);

      BeitySnackBar.success(
        context,
        context.translate('deleted_item_success', arguments: {'name': item.name}),
        actionLabel: context.translate('undo'),
        onAction: () => _undoDelete(),
      );

      _undoTimer?.cancel();
      _undoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _lastDeletedItem = null);
        }
      });
    }
  }

  Future<void> _undoDelete() async {
    if (_lastDeletedItem == null) return;

    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = DeleteItemUseCase(repository);
    await useCase.restoreItem(item: _lastDeletedItem!);

    _undoTimer?.cancel();
    if (mounted) {
      setState(() => _lastDeletedItem = null);
    }
  }

  Future<void> _retryFailedEntries(String homeId) async {
    final repository = ref.read(offlineQueueRepositoryProvider);
    final failedEntries = await repository.getFailedEntries(homeId);

    for (final entry in failedEntries) {
      await repository.updateEntryStatus(
        entryId: entry.id!,
        status: SyncStatus.pending,
      );
    }

    // Refresh providers
    ref.invalidate(queueEntriesProvider(homeId));
    ref.invalidate(pendingCountProvider(homeId));
    ref.invalidate(failedCountProvider(homeId));

    if (mounted) {
      BeitySnackBar.info(
        context,
        context.translate('retrying_items', arguments: {'count': failedEntries.length.toString()}),
      );
    }
  }
}
