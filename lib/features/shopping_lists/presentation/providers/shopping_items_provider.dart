import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../domain/entities/autocomplete_suggestion.dart';
import '../../data/models/shopping_item_model.dart';
import '../../data/models/item_template_model.dart';
import '../../../../core/services/realtime_service.dart';
import 'realtime_providers.dart';

import 'shopping_lists_provider.dart';

final shoppingItemRepositoryProvider = shoppingListRepositoryProvider;

final shoppingItemRepositoryForHomeProvider =
    shoppingListRepositoryForHomeProvider;

final shoppingItemsProvider = StreamProvider.autoDispose
    .family<List<ShoppingItemModel>, String>((ref, listId) {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return repository.watchShoppingItems(listId: listId);
    });

final shoppingItemsForHomeProvider = StreamProvider.autoDispose
    .family<List<ShoppingItemModel>, ({String listId, String homeId})>((
      ref,
      params,
    ) {
      final repository = ref.watch(
        shoppingListRepositoryForHomeProvider(params.homeId),
      );
      return repository.watchShoppingItems(listId: params.listId);
    });

final shoppingItemByIdProvider = FutureProvider.autoDispose
    .family<ShoppingItemModel?, String>((ref, itemId) async {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return repository.getShoppingItemById(itemId: itemId);
    });

final itemTemplatesProvider = StreamProvider.autoDispose
    .family<List<ItemTemplateModel>, String>((ref, homeId) {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return repository.watchItemTemplates(homeId: homeId);
    });

final purchaseHistoryProvider = FutureProvider.autoDispose
    .family<List<ShoppingItemModel>, String>((ref, homeId) async {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return repository.getPurchaseHistory(homeId: homeId);
    });

// Autocomplete suggestions
final autocompleteSuggestionsProvider = FutureProvider.autoDispose
    .family<List<AutocompleteSuggestion>, ({String homeId, String query})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(shoppingListRepositoryProvider);
      return repository.getAutocompleteSuggestions(
        homeId: params.homeId,
        query: params.query,
      );
    });

final presenceProvider = StreamProvider.autoDispose
    .family<Map<String, PresenceState>, String>((ref, listId) {
      final service = ref.watch(realtimeServiceProvider);
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        return Stream.value({});
      }

      final channelName = 'presence:list:$listId';
      ref.onDispose(() => service.unsubscribeChannel(channelName));
      final l10n = ref.read(appLocalizationsProvider);
      return service.watchPresence(
        channelName: channelName,
        userPayload: PresencePayload(
          userId: currentUser.id,
          displayName:
              currentUser.userMetadata?['full_name'] as String? ??
                  l10n.translate('guest_user'),
          avatarUrl: currentUser.userMetadata?['avatar_url'] as String?,
        ),
      );
    });
