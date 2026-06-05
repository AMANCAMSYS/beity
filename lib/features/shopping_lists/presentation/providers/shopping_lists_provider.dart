import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/services/sync_service.dart';
import '../../data/models/shopping_list_model.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/supabase_shopping_list_repository.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/archive_list_usecase.dart';
import '../../domain/usecases/complete_list_usecase.dart';
import '../../../offline_queue/data/repositories/offline_aware_shopping_repository.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../offline_queue/presentation/providers/connectivity_provider.dart';
import '../../../homes/presentation/providers/homes_provider.dart';

import '../../data/datasources/shopping_local_datasource.dart';

final shoppingLocalDataSourceProvider = Provider<ShoppingLocalDataSource>((
  ref,
) {
  return DriftShoppingLocalDataSource();
});

ShoppingListRepository _buildShoppingListRepository(Ref ref, {String? homeId}) {
  final client = SupabaseService.client;
  final remoteRepo = SupabaseShoppingListRepository(client);
  final queueRepo = ref.watch(offlineQueueRepositoryProvider);
  final connectivityRepo = ref.watch(connectivityRepositoryProvider);
  final localDataSource = ref.watch(shoppingLocalDataSourceProvider);
  final syncService = ref.watch(syncServiceProvider);

  return OfflineAwareShoppingRepository(
    remoteRepository: remoteRepo,
    queueRepository: queueRepo,
    connectivityRepository: connectivityRepo,
    localDataSource: localDataSource,
    syncService: syncService,
    homeId: homeId,
  );
}

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final activeHomeId = ref.watch(cachedActiveHomeIdProvider);
  return _buildShoppingListRepository(ref, homeId: activeHomeId);
});

final shoppingListRepositoryForHomeProvider =
    Provider.family<ShoppingListRepository, String>((ref, homeId) {
      return _buildShoppingListRepository(ref, homeId: homeId);
    });

final shoppingListsProvider =
    StreamProvider.family<List<ShoppingListModel>, String>((ref, homeId) {
      if (homeId.isEmpty) {
        return Stream.value([]);
      }

      final repository = ref.watch(
        shoppingListRepositoryForHomeProvider(homeId),
      );
      return repository
          .watchShoppingLists(homeId: homeId)
          .map(_sortShoppingListsByNewest);
    });

List<ShoppingListModel> _sortShoppingListsByNewest(
  List<ShoppingListModel> lists,
) {
  return List<ShoppingListModel>.from(lists)..sort((a, b) {
    final aCreatedAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreatedAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final createdComparison = bCreatedAt.compareTo(aCreatedAt);
    if (createdComparison != 0) return createdComparison;

    final aUpdatedAt = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bUpdatedAt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bUpdatedAt.compareTo(aUpdatedAt);
  });
}

final shoppingListByIdProvider = StreamProvider.autoDispose
    .family<ShoppingListModel?, String>((ref, listId) {
      final localDS = ref.watch(shoppingLocalDataSourceProvider);
      if (localDS is DriftShoppingLocalDataSource) {
        return localDS.watchShoppingListById(listId);
      }
      // Fallback: prime cache then return one-shot
      final repository = ref.watch(shoppingListRepositoryProvider);
      return Stream.fromFuture(
        repository.getShoppingListById(listId: listId),
      );
    });

final shoppingListByIdForHomeProvider = StreamProvider.autoDispose
    .family<ShoppingListModel?, ({String listId, String homeId})>((
      ref,
      params,
    ) {
      final localDS = ref.watch(shoppingLocalDataSourceProvider);
      if (localDS is DriftShoppingLocalDataSource) {
        return localDS.watchShoppingListById(params.listId);
      }
      // Fallback: prime cache then return one-shot
      final repository = ref.watch(
        shoppingListRepositoryForHomeProvider(params.homeId),
      );
      return Stream.fromFuture(
        repository.getShoppingListById(listId: params.listId),
      );
    });

final activeShoppingListsProvider =
    Provider.family<List<ShoppingListModel>, String>((ref, homeId) {
      final lists = ref.watch(shoppingListsProvider(homeId));
      return lists.when(
        data: (data) => data.where((list) => list.isActive).toList(),
        loading: () => [],
        error: (e, s) => [],
      );
    });

final archivedShoppingListsProvider =
    Provider.family<List<ShoppingListModel>, String>((ref, homeId) {
      final lists = ref.watch(shoppingListsProvider(homeId));
      return lists.when(
        data: (data) => data.where((list) => list.isArchived).toList(),
        loading: () => [],
        error: (e, s) => [],
      );
    });

final completedShoppingListsProvider =
    Provider.family<List<ShoppingListModel>, String>((ref, homeId) {
      final lists = ref.watch(shoppingListsProvider(homeId));
      return lists.when(
        data: (data) => data
            .where((list) => list.status == ShoppingListStatus.completed)
            .toList(),
        loading: () => [],
        error: (e, s) => [],
      );
    });

final archiveListUseCaseProvider = Provider<ArchiveListUseCase>((ref) {
  return ArchiveListUseCase(ref.watch(shoppingListRepositoryProvider));
});

final completeListUseCaseProvider = Provider<CompleteListUseCase>((ref) {
  return CompleteListUseCase(ref.watch(shoppingListRepositoryProvider));
});

class ShoppingListSummary {
  final int total;
  final int purchased;
  final int remaining;
  final double progress;

  ShoppingListSummary({required this.total, required this.purchased})
    : remaining = total - purchased,
      progress = total > 0 ? purchased / total : 0.0;
}

final shoppingListSummariesProvider = StreamProvider.autoDispose
    .family<Map<String, ShoppingListSummary>, String>((ref, homeId) {
      if (homeId.isEmpty) return Stream.value({});

      final localDS = ref.watch(shoppingLocalDataSourceProvider);
      if (localDS is DriftShoppingLocalDataSource) {
        // Live reactive stream: emits when shopping_lists OR shopping_items change
        final controller =
            StreamController<Map<String, ShoppingListSummary>>.broadcast();
        final subscriptions = <StreamSubscription>[];

        Future<Map<String, ShoppingListSummary>> compute() async {
          final lists = await localDS.getShoppingListsStreamCache(homeId: homeId);
          final activeLists = lists.where((l) => l.isActive).toList();
          if (activeLists.isEmpty) return {};

          final summaries = <String, ShoppingListSummary>{};
          for (final list in activeLists) {
            final items = await localDS.getShoppingItemsStreamCache(
              listId: list.id,
            );
            final total = items.length;
            final purchased = items.where((i) => i.isPurchased).length;
            summaries[list.id] = ShoppingListSummary(
              total: total,
              purchased: purchased,
            );
          }
          return summaries;
        }

        Future<void> emitLatest() async {
          try {
            controller.add(await compute());
          } catch (_) {}
        }

        // Watch shopping_lists table
        subscriptions.add(
          localDS.watchShoppingListsStreamCache(homeId: homeId).listen(
            (_) => emitLatest(),
          ),
        );

        // Watch all active lists' items by subscribing per-list
        void resubscribeItems(List<ShoppingListModel> lists) {
          // Remove old item subscriptions (keep the lists subscription at index 0)
          for (var i = 1; i < subscriptions.length; i++) {
            subscriptions[i].cancel();
          }
          subscriptions.length = 1;

          final activeLists = lists.where((l) => l.isActive).toList();
          for (final list in activeLists) {
            subscriptions.add(
              localDS.watchShoppingItemsStreamCache(listId: list.id).listen(
                (_) => emitLatest(),
              ),
            );
          }
        }

        // Initial lists subscription also drives item subscription management
        // Replace the first subscription with one that also manages items
        subscriptions[0].cancel();
        subscriptions.clear();
        subscriptions.add(
          localDS.watchShoppingListsStreamCache(homeId: homeId).listen((
            lists,
          ) {
            resubscribeItems(lists);
            emitLatest();
          }),
        );

        ref.onDispose(() {
          for (final sub in subscriptions) {
            sub.cancel();
          }
          controller.close();
        });

        // Prime cache and emit initial value
        emitLatest();

        return controller.stream;
      }

      // Non-Drift fallback: re-emit on list stream changes
      return Stream.value({});
    });
