import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';
import '../../data/repositories/offline_queue_repository.dart';
import '../../data/repositories/connectivity_repository.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../shopping_lists/data/models/item_template_model.dart';
import '../../../shopping_lists/data/repositories/shopping_list_repository.dart';
import '../../../shopping_lists/presentation/providers/shopping_items_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineAwareShoppingRepository implements ShoppingListRepository {
  final ShoppingListRepository _remoteRepository;
  final OfflineQueueRepository _queueRepository;
  final ConnectivityRepository _connectivityRepository;

  OfflineAwareShoppingRepository({
    required ShoppingListRepository remoteRepository,
    required OfflineQueueRepository queueRepository,
    required ConnectivityRepository connectivityRepository,
  })  : _remoteRepository = remoteRepository,
        _queueRepository = queueRepository,
        _connectivityRepository = connectivityRepository;

  Future<bool> get _isOnline async {
    final status = await _connectivityRepository.getCurrentStatus();
    return status.isOnline;
  }

  // Shopping Lists - pass through (lists are managed online)
  @override
  Future<List<ShoppingListModel>> getShoppingLists({
    required String homeId,
    String? status,
  }) {
    return _remoteRepository.getShoppingLists(homeId: homeId, status: status);
  }

  @override
  Future<ShoppingListModel?> getShoppingListById({required String listId}) {
    return _remoteRepository.getShoppingListById(listId: listId);
  }

  @override
  Future<ShoppingListModel> createShoppingList({
    required String homeId,
    required String name,
    String? description,
    String? icon,
  }) {
    return _remoteRepository.createShoppingList(
      homeId: homeId,
      name: name,
      description: description,
      icon: icon,
    );
  }

  @override
  Future<ShoppingListModel> updateShoppingList({
    required String listId,
    String? name,
    String? description,
    String? status,
  }) {
    return _remoteRepository.updateShoppingList(
      listId: listId,
      name: name,
      description: description,
      status: status,
    );
  }

  @override
  Future<void> deleteShoppingList({required String listId}) {
    return _remoteRepository.deleteShoppingList(listId: listId);
  }

  @override
  Stream<List<ShoppingListModel>> watchShoppingLists({required String homeId}) {
    return _remoteRepository.watchShoppingLists(homeId: homeId);
  }

  // Shopping Items - with offline queue support
  @override
  Future<List<ShoppingItemModel>> getShoppingItems({required String listId}) {
    return _remoteRepository.getShoppingItems(listId: listId);
  }

  @override
  Future<ShoppingItemModel?> getShoppingItemById({required String itemId}) {
    return _remoteRepository.getShoppingItemById(itemId: itemId);
  }

  @override
  Future<ShoppingItemModel> createShoppingItem({
    required String listId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
    double? price,
    String? currency,
    String? notes,
  }) async {
    if (await _isOnline) {
      return _remoteRepository.createShoppingItem(
        listId: listId,
        name: name,
        quantity: quantity,
        unitId: unitId,
        categoryId: categoryId,
        price: price,
        currency: currency,
        notes: notes,
      );
    }

    // Queue for offline sync
    await _queueRepository.enqueueAction(
      actionType: ActionType.addItem,
      entityType: EntityType.shoppingItem,
      entityId: listId, // temporary, will be replaced with actual item id
      homeId: listId,
      payload: {
        'listId': listId,
        'name': name,
        'quantity': quantity,
        'unitId': unitId,
        'categoryId': categoryId,
        'price': price,
        'currency': currency,
        'notes': notes,
      },
    );

    // Return a temporary model for optimistic UI
    final user = Supabase.instance.client.auth.currentUser;
    return ShoppingItemModel(
      id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      shoppingListId: listId,
      name: name,
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
      price: price,
      currency: currency ?? 'SAR',
      notes: notes,
      isPurchased: false,
      createdBy: user?.id ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<ShoppingItemModel> updateShoppingItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? price,
    String? notes,
  }) async {
    if (await _isOnline) {
      return _remoteRepository.updateShoppingItem(
        itemId: itemId,
        name: name,
        quantity: quantity,
        unitId: unitId,
        categoryId: categoryId,
        price: price,
        notes: notes,
      );
    }

    // Queue for offline sync
    await _queueRepository.enqueueAction(
      actionType: ActionType.updateItem,
      entityType: EntityType.shoppingItem,
      entityId: itemId,
      homeId: itemId,
      payload: {
        'itemId': itemId,
        'name': name,
        'quantity': quantity,
        'unitId': unitId,
        'categoryId': categoryId,
        'price': price,
        'notes': notes,
      },
    );

    // Return current item (optimistic)
    final current = await _remoteRepository.getShoppingItemById(itemId: itemId);
    return current!;
  }

  @override
  Future<void> deleteShoppingItem({required String itemId}) async {
    if (await _isOnline) {
      return _remoteRepository.deleteShoppingItem(itemId: itemId);
    }

    // Queue for offline sync
    await _queueRepository.enqueueAction(
      actionType: ActionType.deleteItem,
      entityType: EntityType.shoppingItem,
      entityId: itemId,
      homeId: itemId,
      payload: {
        'itemId': itemId,
      },
    );
  }

  @override
  Future<ShoppingItemModel> markItemPurchased({
    required String itemId,
    required bool isPurchased,
  }) async {
    if (await _isOnline) {
      return _remoteRepository.markItemPurchased(
        itemId: itemId,
        isPurchased: isPurchased,
      );
    }

    // Queue for offline sync
    await _queueRepository.enqueueAction(
      actionType: ActionType.markPurchased,
      entityType: EntityType.shoppingItem,
      entityId: itemId,
      homeId: itemId,
      payload: {
        'itemId': itemId,
        'isPurchased': isPurchased,
        'purchasedAt': DateTime.now().toIso8601String(),
      },
    );

    // Return current item (optimistic)
    final current = await _remoteRepository.getShoppingItemById(itemId: itemId);
    return current!;
  }

  @override
  Future<List<ShoppingItemModel>> getPurchaseHistory({
    required String homeId,
    int limit = 50,
  }) {
    return _remoteRepository.getPurchaseHistory(homeId: homeId, limit: limit);
  }

  @override
  Stream<List<ShoppingItemModel>> watchShoppingItems({required String listId}) {
    return _remoteRepository.watchShoppingItems(listId: listId);
  }

  // Item Templates - pass through
  @override
  Future<List<ItemTemplateModel>> getItemTemplates({required String homeId}) {
    return _remoteRepository.getItemTemplates(homeId: homeId);
  }

  @override
  Future<ItemTemplateModel> createItemTemplate({
    required String homeId,
    required String name,
    double defaultQuantity = 1,
    String? defaultUnitId,
    String? defaultCategoryId,
  }) {
    return _remoteRepository.createItemTemplate(
      homeId: homeId,
      name: name,
      defaultQuantity: defaultQuantity,
      defaultUnitId: defaultUnitId,
      defaultCategoryId: defaultCategoryId,
    );
  }

  @override
  Future<void> incrementTemplateUsage({required String templateId}) {
    return _remoteRepository.incrementTemplateUsage(templateId: templateId);
  }

  @override
  Stream<List<ItemTemplateModel>> watchItemTemplates({required String homeId}) {
    return _remoteRepository.watchItemTemplates(homeId: homeId);
  }

  @override
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions({
    required String homeId,
    required String query,
    int limit = 10,
  }) {
    return _remoteRepository.getAutocompleteSuggestions(
      homeId: homeId,
      query: query,
      limit: limit,
    );
  }

  @override
  Future<void> syncTemplateOnAdd({
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
  }) {
    return _remoteRepository.syncTemplateOnAdd(
      homeId: homeId,
      name: name,
      quantity: quantity,
      unitId: unitId,
      categoryId: categoryId,
    );
  }
}
