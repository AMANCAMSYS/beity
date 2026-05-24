import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/shopping_list_model.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/supabase_shopping_list_repository.dart';
import '../../../offline_queue/data/repositories/offline_aware_shopping_repository.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';
import '../../../offline_queue/presentation/providers/connectivity_provider.dart';
import '../../../homes/presentation/providers/homes_provider.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final client = Supabase.instance.client;
  final remoteRepo = SupabaseShoppingListRepository(client);
  final queueRepo = ref.watch(offlineQueueRepositoryProvider);
  final connectivityRepo = ref.watch(connectivityRepositoryProvider);
  final activeHomeId = ref.watch(activeHomeIdProvider).valueOrNull;

  return OfflineAwareShoppingRepository(
    remoteRepository: remoteRepo,
    queueRepository: queueRepo,
    connectivityRepository: connectivityRepo,
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
    error: (_, __) => [],
  );
});

final archivedShoppingListsProvider =
    Provider.autoDispose.family<List<ShoppingListModel>, String>((ref, homeId) {
  final lists = ref.watch(shoppingListsProvider(homeId));
  return lists.when(
    data: (data) => data.where((list) => list.isArchived).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
