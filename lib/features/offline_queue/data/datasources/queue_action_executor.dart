import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';

class QueueActionExecutor {
  final SupabaseClient _client;

  QueueActionExecutor(this._client);

  Future<void> execute(QueueEntry entry) async {
    switch (entry.entityType) {
      case EntityType.shoppingItem:
        await _executeShoppingItemAction(entry);
        break;
      case EntityType.shoppingList:
        await _executeShoppingListAction(entry);
        break;
    }
  }

  Future<void> _executeShoppingItemAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.addItem:
        await _executeAddItem(entry);
        break;
      case ActionType.updateItem:
        await _executeUpdateItem(entry);
        break;
      case ActionType.deleteItem:
        await _executeDeleteItem(entry);
        break;
      case ActionType.markPurchased:
        await _executeMarkPurchased(entry);
        break;
      case ActionType.updateQuantity:
        await _executeUpdateQuantity(entry);
        break;
    }
  }

  Future<void> _executeShoppingListAction(QueueEntry entry) async {
    // Shopping list actions are handled online only
    throw Exception('Shopping list actions not supported in offline queue');
  }

  Future<void> _executeAddItem(QueueEntry entry) async {
    final payload = entry.payload;
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('shopping_items').insert({
      'list_id': payload['listId'],
      'name': payload['name'],
      'quantity': payload['quantity'] ?? 1,
      'unit_id': payload['unitId'],
      'category_id': payload['categoryId'],
      'price': payload['price'],
      'currency': payload['currency'],
      'notes': payload['notes'],
      'created_by': user.id,
    });
  }

  Future<void> _executeUpdateItem(QueueEntry entry) async {
    final payload = entry.payload;
    final itemId = payload['itemId'] as String;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (payload['name'] != null) updates['name'] = payload['name'];
    if (payload['quantity'] != null) updates['quantity'] = payload['quantity'];
    if (payload['unitId'] != null) updates['unit_id'] = payload['unitId'];
    if (payload['categoryId'] != null) {
      updates['category_id'] = payload['categoryId'];
    }
    if (payload['price'] != null) updates['price'] = payload['price'];
    if (payload['notes'] != null) updates['notes'] = payload['notes'];

    await _client.from('shopping_items').update(updates).eq('id', itemId);
  }

  Future<void> _executeDeleteItem(QueueEntry entry) async {
    final itemId = entry.payload['itemId'] as String;

    await _client.from('shopping_items').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  Future<void> _executeMarkPurchased(QueueEntry entry) async {
    final payload = entry.payload;
    final itemId = payload['itemId'] as String;
    final isPurchased = payload['isPurchased'] as bool;

    await _client.from('shopping_items').update({
      'is_purchased': isPurchased,
      'purchased_at': isPurchased ? payload['purchasedAt'] : null,
      'purchased_by': isPurchased ? _client.auth.currentUser?.id : null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  Future<void> _executeUpdateQuantity(QueueEntry entry) async {
    final payload = entry.payload;
    final itemId = payload['itemId'] as String;
    final quantity = payload['quantity'] as double;

    await _client.from('shopping_items').update({
      'quantity': quantity,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }
}
