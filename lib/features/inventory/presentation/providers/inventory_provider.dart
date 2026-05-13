import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/supabase_inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final client = Supabase.instance.client;
  return SupabaseInventoryRepository(client);
});

final inventoryItemsProvider =
    StreamProvider.family<List<InventoryItemModel>, String>((ref, homeId) {
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
    error: (_, __) => {},
  );
});

final lowStockItemsProvider =
    Provider.family<List<InventoryItemModel>, String>((ref, homeId) {
  final items = ref.watch(inventoryItemsProvider(homeId));
  return items.when(
    data: (data) => data.where((item) => item.isLowStock).toList(),
    loading: () => [],
    error: (_, __) => [],
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
