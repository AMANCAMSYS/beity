import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beity/core/services/sync_service.dart';
import '../../data/models/shopping_list_model.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/supabase_shopping_list_repository.dart';
import '../../../offline_queue/data/repositories/offline_aware_shopping_repository.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../offline_queue/presentation/providers/connectivity_provider.dart';
import '../../../homes/presentation/providers/homes_provider.dart';

import '../../data/datasources/shopping_local_datasource.dart';

final shoppingLocalDataSourceProvider = Provider<ShoppingLocalDataSource>((ref) {
  return SharedPreferencesShoppingLocalDataSource();
});

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final client = SupabaseService.client;
  final remoteRepo = SupabaseShoppingListRepository(client);
  final queueRepo = ref.watch(offlineQueueRepositoryProvider);
  final connectivityRepo = ref.watch(connectivityRepositoryProvider);
  final localDataSource = ref.watch(shoppingLocalDataSourceProvider);
  final syncService = ref.watch(syncServiceProvider);
  final activeHomeId = ref.watch(activeHomeIdProvider).valueOrNull;

  return OfflineAwareShoppingRepository(
    remoteRepository: remoteRepo,
    queueRepository: queueRepo,
    connectivityRepository: connectivityRepo,
    localDataSource: localDataSource,
    syncService: syncService,
    homeId: activeHomeId,
  );
});

final shoppingListsProvider =
    StreamProvider.autoDispose.family<List<ShoppingListModel>, String>((ref, homeId) {
  if (homeId.isEmpty) {
    return Stream.value([]);
  }
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.watchShoppingLists(homeId: homeId);
});

final shoppingListByIdProvider =
    FutureProvider.family<ShoppingListModel?, String>((ref, listId) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.getShoppingListById(listId: listId);
});

final activeShoppingListsProvider =
    Provider.autoDispose.family<List<ShoppingListModel>, String>((ref, homeId) {
  final lists = ref.watch(shoppingListsProvider(homeId));
  return lists.when(
    data: (data) => data.where((list) => list.isActive).toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});

final archivedShoppingListsProvider =
    Provider.autoDispose.family<List<ShoppingListModel>, String>((ref, homeId) {
  final lists = ref.watch(shoppingListsProvider(homeId));
  return lists.when(
    data: (data) => data.where((list) => list.isArchived).toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});
