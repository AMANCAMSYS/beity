import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/models/item_template_model.dart';
import '../../../../core/services/realtime_service.dart';
import 'realtime_providers.dart';

import 'shopping_lists_provider.dart';

final shoppingItemRepositoryProvider = shoppingListRepositoryProvider;

final shoppingItemsProvider =
    StreamProvider.autoDispose.family<List<ShoppingItemModel>, String>((ref, listId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.watchShoppingItems(listId: listId);
});

final shoppingItemByIdProvider =
    FutureProvider.family<ShoppingItemModel?, String>((ref, itemId) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.getShoppingItemById(itemId: itemId);
});

final unpurchasedItemsProvider =
    Provider.family<List<ShoppingItemModel>, String>((ref, listId) {
  final items = ref.watch(shoppingItemsProvider(listId));
  return items.when(
    data: (data) => data.where((item) => !item.isPurchased).toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});

final purchasedItemsProvider =
    Provider.family<List<ShoppingItemModel>, String>((ref, listId) {
  final items = ref.watch(shoppingItemsProvider(listId));
  return items.when(
    data: (data) => data.where((item) => item.isPurchased).toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});

final itemTemplatesProvider =
    StreamProvider.family<List<ItemTemplateModel>, String>((ref, homeId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.watchItemTemplates(homeId: homeId);
});

final purchaseHistoryProvider =
    FutureProvider.family<List<ShoppingItemModel>, String>((ref, homeId) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
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
    error: (e, s) => {},
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
    error: (e, s) => 0,
  );
});

// Autocomplete suggestions
final autocompleteSuggestionsProvider = FutureProvider.family<
    List<AutocompleteSuggestion>,
    ({String homeId, String query})>((ref, params) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
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
    StreamProvider.autoDispose.family<Map<String, PresenceState>, String>((ref, listId) {
  final service = ref.watch(realtimeServiceProvider);
  final currentUser = SupabaseService.client.auth.currentUser;
  if (currentUser == null) {
    return Stream.value({});
  }

  final channelName = 'presence:list:$listId';
  ref.onDispose(() => service.unsubscribeChannel(channelName));
  return service.watchPresence(
    channelName: channelName,
    userPayload: PresencePayload(
      userId: currentUser.id,
      displayName: currentUser.userMetadata?['full_name'] as String? ?? 'مستخدم',
      avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
    ),
  );
});
