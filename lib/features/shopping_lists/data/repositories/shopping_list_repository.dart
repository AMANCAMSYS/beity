import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../models/item_template_model.dart';
import '../../domain/entities/autocomplete_suggestion.dart';
import '../../domain/constants/shopping_constants.dart';

export '../../domain/constants/shopping_constants.dart';

abstract class ShoppingListRepository {
  // Shopping Lists
  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
    bool includeDeleted = false,
  });

  Stream<List<ShoppingListModel>> watchShoppingLists({
    required String homeId,
    String? status,
  });

  Future<ShoppingListModel?> getShoppingListById({required String listId});

  Future<ShoppingListModel> createShoppingList({
    String? id,
    required String homeId,
    required String name,
    String? description,
    String? icon,
  });

  Future<ShoppingListModel> updateShoppingList({
    required String listId,
    String? name,
    String? description,
    String? status,
  });

  Future<void> deleteShoppingList({required String listId});

  // Shopping Items
  Future<List<ShoppingItemModel>> getShoppingItems({
    required String listId,
    bool includeDeleted = false,
  });

  Stream<List<ShoppingItemModel>> watchShoppingItems({required String listId});

  Future<Map<String, List<ShoppingItemModel>>> getShoppingItemsForLists({
    required List<String> listIds,
    bool includeDeleted = false,
  });

  Future<ShoppingItemModel?> getShoppingItemById({required String itemId});

  Future<ShoppingItemModel> createShoppingItem({
    String? id,
    required String listId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? price,
    String? currency,
    String? notes,
  });

  Future<ShoppingItemModel> updateShoppingItem({
    required String itemId,
    String? name,
    double? quantity,
    double? purchasedQuantity,
    Object? unitId = shoppingFieldUnchanged,
    Object? categoryId = shoppingFieldUnchanged,
    Object? price = shoppingFieldUnchanged,
    Object? notes = shoppingFieldUnchanged,
  });

  Future<void> deleteShoppingItem({required String itemId});

  Future<ShoppingItemModel> restoreShoppingItem({
    required ShoppingItemModel item,
  });

  Future<ShoppingItemModel> markItemPurchased({
    required String itemId,
    required bool isPurchased,
  });

  Future<ShoppingItemModel> updateItemPurchaseState({
    required String itemId,
    required double purchasedQuantity,
  });

  Future<List<ShoppingItemModel>> getPurchaseHistory({
    required String homeId,
    int limit = 50,
  });

  // Item Templates
  Future<List<ItemTemplateModel>> getItemTemplates({required String homeId});

  Future<ItemTemplateModel> createItemTemplate({
    required String homeId,
    required String name,
    double defaultQuantity = 1,
    String? defaultUnitId,
    String? defaultCategoryId,
  });

  Future<void> incrementTemplateUsage({required String templateId});

  Stream<List<ItemTemplateModel>> watchItemTemplates({required String homeId});

  // Autocomplete suggestions
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions({
    required String homeId,
    required String query,
    int limit = 10,
  });

  // Template sync on add
  Future<void> syncTemplateOnAdd({
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
  });

  Future<void> syncShoppingWithServer(String homeId);
}
