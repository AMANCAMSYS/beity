import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../providers/realtime_providers.dart';
import '../widgets/shopping_item_tile_widget.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/presence_indicator_widget.dart';
import '../widgets/connection_status_widget.dart';
import '../../domain/usecases/mark_item_purchased_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../data/models/shopping_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../offline_queue/presentation/widgets/connectivity_listener.dart';
import '../../../offline_queue/presentation/widgets/sync_status_banner.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../offline_queue/presentation/providers/connectivity_provider.dart';
import '../../../offline_queue/domain/entities/sync_status.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/utils/action_debouncer.dart';

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
  });

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
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final service = ref.read(realtimeServiceProvider);
      if (service.isDisposed) return;
      final channelName = 'presence:list:${widget.listId}';
      service.watchPresence(
        channelName: channelName,
        userPayload: PresencePayload(
          userId: currentUser.id,
          displayName: currentUser.userMetadata?['full_name'] as String? ?? 'مستخدم',
          avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
        ),
      );
    } catch (_) {
      // Service may be disposed during logout transition
    }
  }

  void _leavePresence() {
    try {
      final service = ref.read(realtimeServiceProvider);
      if (!service.isDisposed) {
        final channelName = 'presence:list:${widget.listId}';
        service.leavePresence(channelName: channelName);
      }
    } catch (_) {
      // Service may already be disposed on logout
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = theme.brightness == Brightness.dark;

    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));
    final itemsAsync = ref.watch(shoppingItemsProvider(widget.listId));
    final connectionState = ref.watch(connectionStateProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    final list = listAsync.valueOrNull;
    final homeId = list?.homeId ?? '';
    final presenceAsync = ref.watch(presenceProvider(widget.listId));

    // Load units for display
    final unitsAsync = ref.watch(unitsProvider(null));
    final unitNames = <String, String>{};
    unitsAsync.whenData((units) {
      for (final unit in units) {
        unitNames[unit.id] = unit.symbol.isNotEmpty ? '${unit.name} (${unit.symbol})' : unit.name;
      }
    });

    // Load categories for filter
    final categoriesAsync = ref.watch(categoriesProvider(homeId));

    // Offline queue status
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final isOffline = connectivityStatus.valueOrNull?.isOffline ?? false;
    final pendingCount = homeId.isNotEmpty
        ? ref.watch(pendingCountProvider(homeId)).valueOrNull ?? 0
        : 0;
    final failedEntries = homeId.isNotEmpty
        ? ref
            .watch(offlineQueueRepositoryProvider)
            .getFailedEntries(homeId)
            .then((entries) => entries.length)
        : Future.value(0);

    return ConnectivityListener(
      homeId: homeId,
      child: Scaffold(
      appBar: AppBar(
        title: listAsync.when(
          data: (list) => Text(
            list?.name ?? (isArabic ? 'قائمة التسوق' : 'Shopping List'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => Text(isArabic ? 'جاري التحميل...' : 'Loading...'),
          error: (_, __) => Text(isArabic ? 'حدث خطأ' : 'Error occurred'),
        ),
        actions: [
          if (FeatureFlags.enableAi)
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
              onPressed: () => ActionDebouncer.execute(() async {
                final list = listAsync.valueOrNull;
                if (list != null) {
                  final existingItemNames = itemsAsync.valueOrNull?.map((e) => e.name).toList() ?? [];
                  context.push('/shopping-list/${widget.listId}/ai-suggestions',
                      extra: {
                        'listId': list.id,
                        'listTitle': list.name,
                        'homeId': list.homeId,
                        'homeType': 'family',
                        'existingItemNames': existingItemNames,
                      });
                }
              }),
              tooltip: isArabic ? 'اقتراحات ذكية' : 'Smart Suggestions',
            ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded),
            onPressed: () => ActionDebouncer.execute(() async {
              final list = listAsync.valueOrNull;
              if (list != null) {
                context.push('/shopping-list/${widget.listId}/shopping-mode',
                    extra: {
                      'homeId': list.homeId,
                      'listName': list.name,
                    });
              }
            }),
            tooltip: isArabic ? 'بدء التسوق' : 'Start Shopping',
          ),
          IconButton(
            icon: const Icon(Icons.summarize_rounded),
            onPressed: () => ActionDebouncer.execute(() =>
                context.push('/shopping-list/${widget.listId}/summary')),
            tooltip: isArabic ? 'ملخص القائمة' : 'List Summary',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => ActionDebouncer.execute(() => context.push(
              '/shopping-list/${widget.listId}/activity',
              extra: {
                'homeId': list?.homeId ?? '',
                'listName': list?.name ?? (isArabic ? 'القائمة' : 'List'),
              },
            )),
            tooltip: isArabic ? 'سجل النشاطات' : 'Activity Log',
          ),
          IconButton(
            icon: const Icon(Icons.bolt_rounded),
            onPressed: () => ActionDebouncer.execute(() => context.push(
              '/shopping-list/${widget.listId}/quick-add',
              extra: list?.homeId ?? '',
            )),
            tooltip: isArabic ? 'إضافة سريعة' : 'Quick Add',
          ),
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline sync status banner
          FutureBuilder<int>(
            future: failedEntries,
            builder: (context, snapshot) {
              return SyncStatusBanner(
                pendingCount: pendingCount,
                failedCount: snapshot.data ?? 0,
                isOffline: isOffline,
                onRetryAll: () => _retryFailedEntries(homeId, isArabic),
              );
            },
          ),
          // Connection status
          connectionState.when(
            data: (state) => ConnectionStatusWidget(connectionState: state),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Presence indicators
          presenceAsync.when(
            data: (presences) => PresenceIndicatorWidget(
              presences: presences,
              currentUserId: currentUser?.id ?? '',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Main content
          Expanded(
            child: listAsync.when(
              data: (list) {
                if (list == null) {
                  return BeityEmptyState(
                    title: isArabic ? 'القائمة غير موجودة' : 'List not found',
                    message: isArabic ? 'عذراً، لم نتمكن من العثور على هذه القائمة' : 'Sorry, we couldn\'t find this list',
                    icon: Icons.error_outline_rounded,
                    isError: true,
                    actionText: isArabic ? 'العودة للقوائم' : 'Back to Lists',
                    onActionPressed: () => ActionDebouncer.execute(() async => context.go('/shopping-lists')),
                  );
                }
                
                return itemsAsync.when(
                  data: (items) {
                if (items.isEmpty) {
                  return BeityEmptyState(
                    title: isArabic ? 'القائمة فارغة' : 'List is empty',
                    message: isArabic ? 'ابدأ بإضافة المنتجات التي تحتاج لشرائها' : 'Start by adding items you need to buy',
                    icon: Icons.shopping_basket_rounded,
                    actionText: isArabic ? 'إضافة أول منتج' : 'Add First Item',
                    onActionPressed: () => ActionDebouncer.execute(() => context.push('/shopping-list/${widget.listId}/add-item')),
                  );
                }

                var filtered = items;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((i) => i.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (_filterCategoryId != null) {
                  filtered = filtered
                      .where((i) => i.categoryId == _filterCategoryId)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return BeityEmptyState(
                    title: isArabic ? 'لا توجد نتائج' : 'No results found',
                    message: isArabic ? 'جرب البحث عن شيء آخر أو امسح الفلاتر' : 'Try searching for something else or clear filters',
                    icon: Icons.search_off_rounded,
                    actionText: isArabic ? 'مسح الفلاتر' : 'Clear Filters',
                    onActionPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterCategoryId = null;
                        _searchController.clear();
                      });
                    },
                  );
                }

                final grouped = <String?, List<ShoppingItemModel>>{};
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
                final unpurchasedTotal = items
                    .where((i) => !i.isPurchased && i.price != null)
                    .fold<double>(0, (sum, i) => sum + i.price!);

                return Column(
                  children: [
                    if (_isSearchVisible)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: isArabic ? 'بحث في العناصر...' : 'Search items...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                    categoriesAsync.when(
                      data: (categories) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: CategoryFilterWidget(
                          categories: categories,
                          selectedCategoryId: _filterCategoryId,
                          onCategorySelected: (id) {
                            setState(() => _filterCategoryId = id);
                          },
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        children: [
                          ...grouped.entries.map((entry) {
                            final categoryId = entry.key;
                            final groupItems = entry.value;
                            final isExpanded =
                                _expandedCategories[categoryId] ?? true;

                            return _buildCategoryGroup(
                              context,
                              categoryId: categoryId,
                              items: groupItems,
                              isExpanded: isExpanded,
                              homeId: homeId,
                              unitNames: unitNames,
                              isArabic: isArabic,
                            );
                          }),
                          const SizedBox(height: 100), // Space for bottom bar and FAB
                        ],
                      ),
                    ),
                    if (unpurchasedTotal > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isArabic ? 'المجموع المتوقع' : 'Estimated Total',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isArabic ? 'للمنتجات غير المشتراة' : 'For unpurchased items',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                ),
                                child: Text(
                                  '${unpurchasedTotal.toStringAsFixed(2)} ${isArabic ? 'ر.س' : 'SAR'}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => BeityEmptyState(
                  title: isArabic ? 'خطأ في تحميل العناصر' : 'Error loading items',
                  message: error.toString(),
                  icon: Icons.error_outline_rounded,
                  isError: true,
                  actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
                  onActionPressed: () => ref.invalidate(shoppingItemsProvider(widget.listId)),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => BeityEmptyState(
              title: isArabic ? 'خطأ في تحميل القائمة' : 'Error loading list',
              message: error.toString(),
              icon: Icons.error_outline_rounded,
              isError: true,
              actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
              onActionPressed: () => ref.invalidate(shoppingListByIdProvider(widget.listId)),
            ),
          ),
        ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            ActionDebouncer.execute(() async => context.push('/shopping-list/${widget.listId}/add-item')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(isArabic ? 'إضافة منتج' : 'Add Item', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ),
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context, {
    required String? categoryId,
    required List<ShoppingItemModel> items,
    required bool isExpanded,
    required String homeId,
    required Map<String, String> unitNames,
    required bool isArabic,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryName = _getCategoryName(categoryId, homeId, isArabic);
    final unpurchasedCount = items.where((i) => !i.isPurchased).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedCategories[categoryId] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  size: 24,
                ),
                AppSpacing.gapXS,
                Text(
                  categoryName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapSM,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Text(
                    '$unpurchasedCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...items.map((item) {
            // Check if item has pending offline changes
            final queueEntries = ref.watch(queueEntriesProvider(homeId));
            final hasPending = queueEntries.when(
              data: (entries) => entries.any(
                (e) => e.entityId == item.id && e.isPending,
              ),
              loading: () => false,
              error: (_, __) => false,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ShoppingItemTileWidget(
                item: item,
                unitName: item.unitId != null ? unitNames[item.unitId] : null,
                highlightUntil: _highlightedItems[item.id],
                showPendingIndicator: hasPending,
                onTogglePurchased: () =>
                    ActionDebouncer.execute(() => _togglePurchased(item.id, !item.isPurchased)),
                onEdit: () => ActionDebouncer.execute(() => context.push(
                    '/shopping-list/${widget.listId}/edit-item/${item.id}')),
                onDelete: () => ActionDebouncer.execute(() => _deleteItem(item, isArabic)),
              ),
            );
          }),
        AppSpacing.gapSM,
      ],
    );
  }

  String _getCategoryName(String? categoryId, String homeId, bool isArabic) {
    if (categoryId == null) return isArabic ? 'بدون تصنيف' : 'Uncategorized';

    final categoriesAsync = ref.read(categoriesProvider(homeId));
    return categoriesAsync.when(
      data: (categories) {
        final cat = categories.where((c) => c.id == categoryId).firstOrNull;
        return cat?.name ?? (isArabic ? 'بدون تصنيف' : 'Uncategorized');
      },
      loading: () => isArabic ? 'جاري التحميل...' : 'Loading...',
      error: (_, __) => isArabic ? 'بدون تصنيف' : 'Uncategorized',
    );
  }



  Future<void> _togglePurchased(String itemId, bool isPurchased) async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = MarkItemPurchasedUseCase(repository);
    await useCase(itemId: itemId, isPurchased: isPurchased);
  }

  Future<void> _deleteItem(ShoppingItemModel item, bool isArabic) async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final useCase = DeleteItemUseCase(repository);

    final deletedItem = await useCase.callAndReturn(itemId: item.id);

    if (mounted && deletedItem != null) {
      setState(() => _lastDeletedItem = deletedItem);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          content: Text(isArabic ? 'تم حذف "${item.name}"' : 'Deleted "${item.name}"'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: isArabic ? 'تراجع' : 'Undo',
            textColor: Colors.amber,
            onPressed: () => _undoDelete(),
          ),
        ),
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

  Future<void> _retryFailedEntries(String homeId, bool isArabic) async {
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(isArabic ? 'جاري إعادة محاولة ${failedEntries.length} عنصر' : 'Retrying ${failedEntries.length} items'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}
