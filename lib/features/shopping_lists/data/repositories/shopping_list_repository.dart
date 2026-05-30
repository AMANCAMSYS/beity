import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';
import '../models/item_template_model.dart';
import '../../presentation/providers/shopping_items_provider.dart';

abstract class ShoppingListRepository {
  // Shopping Lists
  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
  });

  Future<ShoppingListModel?> getShoppingListById({
    required String listId,
  });

  Future<ShoppingListModel> createShoppingList({
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

  Future<void> deleteShoppingList({
    required String listId,
  });

  Stream<List<ShoppingListModel>> watchShoppingLists({
    required String homeId,
  });

  // Shopping Items
  Future<List<ShoppingItemModel>> getShoppingItems({
    required String listId,
  });

  Future<ShoppingItemModel?> getShoppingItemById({
    required String itemId,
  });

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
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  });

  Future<void> deleteShoppingItem({
    required String itemId,
  });

  Future<ShoppingItemModel> markItemPurchased({
    required String itemId,
    required bool isPurchased,
  });

  Future<List<ShoppingItemModel>> getPurchaseHistory({
    required String homeId,
    int limit = 50,
  });

  Stream<List<ShoppingItemModel>> watchShoppingItems({
    required String listId,
  });

  // Item Templates
  Future<List<ItemTemplateModel>> getItemTemplates({
    required String homeId,
  });

  Future<ItemTemplateModel> createItemTemplate({
    required String homeId,
    required String name,
    double defaultQuantity = 1,
    String? defaultUnitId,
    String? defaultCategoryId,
  });

  Future<void> incrementTemplateUsage({
    required String templateId,
  });

  Stream<List<ItemTemplateModel>> watchItemTemplates({
    required String homeId,
  });

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
