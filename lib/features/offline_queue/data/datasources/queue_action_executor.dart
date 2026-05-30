import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/queue_entry.dart';
import '../../domain/entities/action_type.dart';
import '../../domain/entities/entity_type.dart';

class QueueActionExecutor {
  final SupabaseClient _client;

  QueueActionExecutor(this._client);

  Future<String?> execute(QueueEntry entry) async {
    final user = _client.auth.currentUser;
    
    // 1. Pre-check idempotency key to prevent duplicate execution
    if (user != null) {
      try {
        final existingLog = await _client
            .from('sync_operations_log')
            .select('idempotency_key')
            .eq('idempotency_key', entry.idempotencyKey)
            .maybeSingle();

        if (existingLog != null) {
          // Operation already executed! Return the entity ID immediately.
          return entry.entityId;
        }
      } catch (_) {
        // Fallback: if the idempotency log table isn't created or queried, proceed with best effort execution
      }
    }

    // 2. Execute the actual database transaction
    String? resultId;
    switch (entry.entityType) {
      case EntityType.shoppingItem:
        resultId = await _executeShoppingItemAction(entry);
        break;
      case EntityType.shoppingList:
        resultId = await _executeShoppingListAction(entry);
        break;
    }

    // 3. Register the idempotency key upon successful execution
    if (user != null) {
      try {
        await _client.from('sync_operations_log').insert({
          'idempotency_key': entry.idempotencyKey,
          'user_id': user.id,
          'entity_type': entry.entityType.tableName,
          'entity_id': entry.entityId,
          'operation_type': entry.actionType.name,
        });
      } catch (_) {
        // If writing to the log table fails, proceed anyway so the sync queue isn't blocked
      }
    }

    return resultId ?? entry.entityId;
  }

  Future<String?> _executeShoppingItemAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.addItem:
        return _executeAddItem(entry);
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
    return null;
  }

  Future<String?> _executeShoppingListAction(QueueEntry entry) async {
    // Shopping list actions are handled online only
    throw Exception('Shopping list actions not supported in offline queue');
  }

  Future<String?> _executeAddItem(QueueEntry entry) async {
    final payload = entry.payload;
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final table = entry.entityType.tableName;
    // Use upsert with the pre-generated ID so that subsequent
    // update/delete/markPurchased entries referencing this ID work correctly
    final result = await _client.from(table).upsert({
      'id': entry.entityId,
      'list_id': payload['list_id'],
      'name': payload['name'],
      'quantity': payload['quantity'] ?? 1,
      'unit_id': payload['unit_id'],
      'category_id': payload['category_id'],
      'estimated_price': payload['estimated_price'],
      'currency': payload['currency'] ?? 'SAR',
      'note': payload['note'],
      'created_by': user.id,
    }, onConflict: 'id').select('id').maybeSingle();

    return result?['id'] as String?;
  }

  Future<void> _executeUpdateItem(QueueEntry entry) async {
    final payload = entry.payload;
    final table = entry.entityType.tableName;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': _client.auth.currentUser?.id,
    };

    if (payload['name'] != null) updates['name'] = payload['name'];
    if (payload['quantity'] != null) updates['quantity'] = payload['quantity'];
    if (payload['unit_id'] != null) updates['unit_id'] = payload['unit_id'];
    if (payload['category_id'] != null) {
      updates['category_id'] = payload['category_id'];
    }
    if (payload['note'] != null) updates['note'] = payload['note'];

    await _client.from(table).update(updates).eq('id', entry.entityId);
  }

  Future<void> _executeDeleteItem(QueueEntry entry) async {
    final table = entry.entityType.tableName;
    await _client.from(table).update({
      'deleted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': _client.auth.currentUser?.id,
    }).eq('id', entry.entityId);
  }

  Future<void> _executeMarkPurchased(QueueEntry entry) async {
    final payload = entry.payload;
    final table = entry.entityType.tableName;
    final user = _client.auth.currentUser;

    final isPurchased = payload['status'] == 'completed';

    await _client.from(table).update({
      'status': payload['status'] ?? (isPurchased ? 'completed' : 'pending'),
      'completed_at': isPurchased
          ? (payload['completed_at'] ?? DateTime.now().toIso8601String())
          : null,
      'completed_by': isPurchased ? (user?.id) : null,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': user?.id,
    }).eq('id', entry.entityId);
  }

  Future<void> _executeUpdateQuantity(QueueEntry entry) async {
    final payload = entry.payload;
    final table = entry.entityType.tableName;

    await _client.from(table).update({
      'quantity': payload['quantity'],
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': _client.auth.currentUser?.id,
    }).eq('id', entry.entityId);
  }
}
