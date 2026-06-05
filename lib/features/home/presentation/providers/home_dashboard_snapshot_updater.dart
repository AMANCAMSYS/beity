import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../activity_logs/presentation/providers/activity_logs_provider.dart';
import '../../../activity_logs/data/models/activity_log_model.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../data/models/home_dashboard_snapshot.dart';
import '../../data/datasources/home_dashboard_snapshot_datasource.dart';

/// Provider that monitors the items of the active list of a home reactively and safely.
final activeListItemsProvider =
    Provider.family<AsyncValue<List<ShoppingItemModel>>, String>((ref, homeId) {
      final listsAsync = ref.watch(shoppingListsProvider(homeId));
      return listsAsync.when(
        data: (lists) {
          final activeLists = lists.where((l) => l.isActive).toList();
          if (activeLists.isEmpty) return const AsyncValue.data([]);
          return ref.watch(
            shoppingItemsForHomeProvider((
              listId: activeLists.first.id,
              homeId: homeId,
            )),
          );
        },
        error: (err, stack) => AsyncValue.error(err, stack),
        loading: () => const AsyncValue.loading(),
      );
    });

/// Background listener provider that monitors live features to compile and save dashboard snapshots.
final homeDashboardSnapshotUpdaterProvider = Provider.family<void, String>((
  ref,
  homeId,
) {
  if (homeId.isEmpty) return;

  final activeHome = ref.watch(cachedActiveHomeProvider);
  if (activeHome == null) return;

  // 1. Listen to shopping lists changes
  ref.listen<AsyncValue<List<ShoppingListModel>>>(
    shoppingListsProvider(homeId),
    (previous, next) {
      next.whenData((lists) {
        final activeLists = lists.where((l) => l.isActive).toList();
        _updateSnapshot(
          ref,
          homeId,
          activeHome.name,
          lists: lists,
          activeList: activeLists.isNotEmpty ? activeLists.first : null,
        );
      });
    },
    fireImmediately: true,
  );

  // 2. Listen to items of the active list reactively and safely
  ref.listen<AsyncValue<List<ShoppingItemModel>>>(
    activeListItemsProvider(homeId),
    (previous, next) {
      next.whenData((items) {
        final total = items.length;
        final purchased = items.where((i) => i.isPurchased == true).length;
        final remaining = total - purchased;

        _updateSnapshot(
          ref,
          homeId,
          activeHome.name,
          remainingCount: remaining,
          totalCount: total,
        );
      });
    },
    fireImmediately: true,
  );

  // 3. Listen to activity logs changes
  ref.listen<AsyncValue<List<ActivityLogModel>>>(
    recentHomeActivityProvider(homeId),
    (previous, next) {
      next.whenData((activities) {
        if (activities.isNotEmpty) {
          _updateSnapshot(ref, homeId, activeHome.name, activities: activities);
        }
      });
    },
    fireImmediately: true,
  );
});

void _updateSnapshot(
  Ref ref,
  String homeId,
  String homeName, {
  List<ShoppingListModel>? lists,
  ShoppingListModel? activeList,
  int? remainingCount,
  int? totalCount,
  List<ActivityLogModel>? activities,
}) async {
  try {
    final datasource = ref.read(homeDashboardSnapshotDatasourceProvider);
    final l10n = ref.read(appLocalizationsProvider);
    final current = datasource.getSnapshot(homeId);
    final hasNoActiveLists = lists != null && activeList == null;

    final updated = HomeDashboardSnapshot(
      homeId: homeId,
      homeName: homeName,
      activeListId: hasNoActiveLists
          ? null
          : activeList?.id ?? current?.activeListId,
      activeListName: hasNoActiveLists
          ? null
          : activeList?.name ?? current?.activeListName,
      remainingShoppingItemsCount: hasNoActiveLists
          ? 0
          : remainingCount ?? current?.remainingShoppingItemsCount ?? 0,
      totalShoppingItemsCount: hasNoActiveLists
          ? 0
          : totalCount ?? current?.totalShoppingItemsCount ?? 0,
      totalActiveListsCount:
          lists?.where((l) => l.isActive).length ??
          current?.totalActiveListsCount ??
          0,
      lastActivityText: activities != null && activities.isNotEmpty
          ? _formatActivityText(activities.first, l10n)
          : current?.lastActivityText,
      updatedAt: DateTime.now(),
    );

    if (current != null && _sameSnapshotContent(current, updated)) {
      return;
    }

    await datasource.saveSnapshot(updated);
  } catch (_) {}
}

bool _sameSnapshotContent(HomeDashboardSnapshot a, HomeDashboardSnapshot b) {
  return a.homeId == b.homeId &&
      a.homeName == b.homeName &&
      a.activeListId == b.activeListId &&
      a.activeListName == b.activeListName &&
      a.remainingShoppingItemsCount == b.remainingShoppingItemsCount &&
      a.totalShoppingItemsCount == b.totalShoppingItemsCount &&
      a.totalActiveListsCount == b.totalActiveListsCount &&
      a.lastActivityText == b.lastActivityText;
}

String _formatActivityText(ActivityLogModel activity, AppLocalizations l10n) {
  final actor = activity.actorName ?? l10n.translate('guest_user');
  final entity = activity.entityName ?? '';
  switch (activity.action.value) {
    case 'item_added':
      return l10n.translate(
        'activity_snapshot_item_added',
        arguments: {'actor': actor, 'entity': entity},
      );
    case 'item_purchased':
      return l10n.translate(
        'activity_snapshot_item_purchased',
        arguments: {'actor': actor, 'entity': entity},
      );
    case 'list_created':
      return l10n.translate(
        'activity_snapshot_list_created',
        arguments: {'actor': actor, 'entity': entity},
      );
    case 'member_joined':
      return l10n.translate(
        'activity_snapshot_member_joined',
        arguments: {'actor': actor},
      );
    default:
      return '$actor: $entity';
  }
}
