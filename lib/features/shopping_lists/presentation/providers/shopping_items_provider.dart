import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/models/item_template_model.dart';
import '../../data/repositories/shopping_list_repository.dart';
import '../../data/repositories/supabase_shopping_list_repository.dart';
import '../../../../core/services/realtime_service.dart';
import 'realtime_providers.dart';

final shoppingItemRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final client = Supabase.instance.client;
  return SupabaseShoppingListRepository(client);
});

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItemModel>, String>((ref, listId) {
  final repository = ref.watch(shoppingItemRepositoryProvider);
  return repository.watchShoppingItems(listId: listId);
});

final shoppingItemByIdProvider =
    FutureProvider.family<ShoppingItemModel?, String>((ref, itemId) async {
  final repository = ref.watch(shoppingItemRepositoryProvider);
  return repository.getShoppingItemById(itemId: itemId);
});

final unpurchasedItemsProvider =
    Provider.family<List<ShoppingItemModel>, String>((ref, listId) {
  final items = ref.watch(shoppingItemsProvider(listId));
  return items.when(
    data: (data) => data.where((item) => !item.isPurchased).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final purchasedItemsProvider =
    Provider.family<List<ShoppingItemModel>, String>((ref, listId) {
  final items = ref.watch(shoppingItemsProvider(listId));
  return items.when(
    data: (data) => data.where((item) => item.isPurchased).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final itemTemplatesProvider =
    StreamProvider.family<List<ItemTemplateModel>, String>((ref, homeId) {
  final repository = ref.watch(shoppingItemRepositoryProvider);
  return repository.watchItemTemplates(homeId: homeId);
});

final purchaseHistoryProvider =
    FutureProvider.family<List<ShoppingItemModel>, String>((ref, homeId) async {
  final repository = ref.watch(shoppingItemRepositoryProvider);
  return repository.getPurchaseHistory(homeId: homeId);
});

// Group items by category_id; null category goes under "uncategorized"
final groupedItemsProvider =
    Provider.family<Map<String?, List<ShoppingItemModel>>, String>(
        (ref, listId) {
  final items = ref.watch(shoppingItemsProvider(listId));
  return items.when(
    data: (data) {
      final map = <String?, List<ShoppingItemModel>>{};
      for (final item in data) {
        map.putIfAbsent(item.categoryId, () => []).add(item);
      }
      // Sort within each group: unpurchased first, then purchased
      for (final group in map.values) {
        group.sort((a, b) {
          if (a.isPurchased == b.isPurchased) return 0;
          return a.isPurchased ? 1 : -1;
        });
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Unpurchased total price
final unpurchasedTotalProvider =
    Provider.family<double, String>((ref, listId) {
  final items = ref.watch(shoppingItemsProvider(listId));
  return items.when(
    data: (data) => data
        .where((item) => !item.isPurchased && item.price != null)
        .fold<double>(0, (sum, item) => sum + item.price!),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Autocomplete suggestions
final autocompleteSuggestionsProvider = FutureProvider.family<
    List<AutocompleteSuggestion>,
    ({String homeId, String query})>((ref, params) async {
  final repository = ref.watch(shoppingItemRepositoryProvider);
  return repository.getAutocompleteSuggestions(
    homeId: params.homeId,
    query: params.query,
  );
});

class AutocompleteSuggestion {
  final String name;
  final double quantity;
  final String? unitName;
  final String? sourceId;
  final bool isTemplate;

  const AutocompleteSuggestion({
    required this.name,
    required this.quantity,
    this.unitName,
    this.sourceId,
    this.isTemplate = false,
  });
}

final presenceProvider =
    StreamProvider.family<Map<String, PresenceState>, String>((ref, listId) {
  final service = ref.watch(realtimeServiceProvider);
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) {
    return Stream.value({});
  }

  final channelName = 'presence:list:$listId';
  return service.watchPresence(
    channelName: channelName,
    userPayload: PresencePayload(
      userId: currentUser.id,
      displayName: currentUser.userMetadata?['full_name'] as String? ?? 'مستخدم',
      avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
    ),
  );
});
