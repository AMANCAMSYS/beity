import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/shopping_list_model.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/supabase_shopping_list_repository.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final client = Supabase.instance.client;
  return SupabaseShoppingListRepository(client);
});

final shoppingListsProvider =
    StreamProvider.family<List<ShoppingListModel>, String>((ref, homeId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.watchShoppingLists(homeId: homeId);
});

final shoppingListByIdProvider =
    FutureProvider.family<ShoppingListModel?, String>((ref, listId) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.getShoppingListById(listId: listId);
});

final activeShoppingListsProvider =
    Provider.family<List<ShoppingListModel>, String>((ref, homeId) {
  final lists = ref.watch(shoppingListsProvider(homeId));
  return lists.when(
    data: (data) => data.where((list) => list.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final archivedShoppingListsProvider =
    Provider.family<List<ShoppingListModel>, String>((ref, homeId) {
  final lists = ref.watch(shoppingListsProvider(homeId));
  return lists.when(
    data: (data) => data.where((list) => list.isArchived).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
