import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beity/core/services/sync_service.dart';
import '../../data/datasources/inventory_local_datasource.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/supabase_inventory_repository.dart';
import '../../domain/usecases/add_purchased_to_inventory_usecase.dart';

final inventoryLocalDataSourceProvider = Provider<InventoryLocalDataSource>((ref) {
  return SharedPreferencesInventoryLocalDataSource();
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final client = SupabaseService.client;
  final localDataSource = ref.watch(inventoryLocalDataSourceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return SupabaseInventoryRepository(client, localDataSource, syncService);
});

final inventoryItemsProvider =
    StreamProvider.autoDispose.family<List<InventoryItemModel>, String>((ref, homeId) {
  if (homeId.isEmpty) {
    return Stream.value([]);
  }
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchInventoryItems(homeId: homeId);
});

final inventoryItemByIdProvider =
    FutureProvider.family<InventoryItemModel?, String>((ref, itemId) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getInventoryItemById(itemId: itemId);
});

final groupedInventoryItemsProvider =
    Provider.family<Map<String?, List<InventoryItemModel>>, String>(
        (ref, homeId) {
  final items = ref.watch(inventoryItemsProvider(homeId));
  return items.when(
    data: (data) {
      final map = <String?, List<InventoryItemModel>>{};
      for (final item in data) {
        map.putIfAbsent(item.categoryId, () => []).add(item);
      }
      return map;
    },
    loading: () => {},
    error: (e, s) => {},
  );
});

final lowStockItemsProvider =
    Provider.family<List<InventoryItemModel>, String>((ref, homeId) {
  final items = ref.watch(inventoryItemsProvider(homeId));
  return items.when(
    data: (data) => data.where((item) => item.isLowStock).toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});

final inventorySearchProvider = FutureProvider.family<
    List<InventoryItemModel>,
    ({String homeId, String query})>((ref, params) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.searchInventoryItems(
    homeId: params.homeId,
    query: params.query,
  );
});

final addPurchasedToInventoryUseCaseProvider =
    Provider<AddPurchasedToInventoryUseCase>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return AddPurchasedToInventoryUseCase(repository);
});
