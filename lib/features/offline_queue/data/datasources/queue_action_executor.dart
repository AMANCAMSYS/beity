import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/core/local_database/daos/categories_dao.dart';
import 'package:sawa/core/local_database/daos/invitations_dao.dart';
import 'package:sawa/core/local_database/daos/notification_preferences_dao.dart';
import 'package:sawa/core/local_database/daos/notifications_dao.dart';
import 'package:sawa/core/local_database/daos/shopping_mode_sessions_dao.dart';
import 'package:sawa/core/local_database/daos/units_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/categories/data/models/unit_model.dart';
import 'package:sawa/features/shopping_mode/data/models/shopping_mode_session_model.dart';

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
      case EntityType.category:
        resultId = await _executeCategoryAction(entry);
        break;
      case EntityType.unit:
        resultId = await _executeUnitAction(entry);
        break;
      case EntityType.shoppingModeSession:
        resultId = await _executeShoppingModeSessionAction(entry);
        break;
      case EntityType.notification:
        resultId = await _executeNotificationAction(entry);
        break;
      case EntityType.notificationPreference:
        resultId = await _executeNotificationPreferenceAction(entry);
        break;
      case EntityType.invitation:
        resultId = await _executeInvitationAction(entry);
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
      case ActionType.restoreItem:
        await _executeRestoreItem(entry);
        break;
      case ActionType.markPurchased:
        await _executeMarkPurchased(entry);
        break;
      case ActionType.updateQuantity:
        await _executeUpdateQuantity(entry);
        break;
      default:
        throw Exception(
          'Shopping item action not supported in offline queue: ${entry.actionType}',
        );
    }
    return null;
  }

  Future<String?> _executeShoppingListAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.addItem:
        return _executeAddShoppingList(entry);
      case ActionType.updateItem:
        await _executeUpdateShoppingList(entry);
        return null;
      case ActionType.deleteItem:
        await _assertBaseRevisionStillCurrent(entry);
        final table = entry.entityType.tableName;
        await _client
            .from(table)
            .update({
              'deleted_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'updated_by': _client.auth.currentUser?.id,
            })
            .eq('id', entry.entityId);
        return null;
      default:
        throw Exception(
          'Shopping list action not supported in offline queue: ${entry.actionType}',
        );
    }
  }

  Future<String?> _executeCategoryAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.createCategory:
        return _executeCreateCategory(entry);
      case ActionType.updateCategory:
        await _executeUpdateCategory(entry);
        return null;
      case ActionType.deleteCategory:
        await _executeDeleteCategory(entry);
        return null;
      default:
        throw Exception(
          'Category action not supported in offline queue: ${entry.actionType}',
        );
    }
  }

  Future<String?> _executeUnitAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.createUnit:
        return _executeCreateUnit(entry);
      case ActionType.updateUnit:
        await _executeUpdateUnit(entry);
        return null;
      case ActionType.deleteUnit:
        await _executeDeleteUnit(entry);
        return null;
      default:
        throw Exception(
          'Unit action not supported in offline queue: ${entry.actionType}',
        );
    }
  }

  Future<String?> _executeShoppingModeSessionAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.startShoppingModeSession:
        return _executeStartShoppingModeSession(entry);
      case ActionType.endShoppingModeSession:
        await _executeEndShoppingModeSession(entry);
        return null;
      default:
        throw Exception(
          'Shopping mode session action not supported in offline queue: ${entry.actionType}',
        );
    }
  }

  Future<String?> _executeAddShoppingList(QueueEntry entry) async {
    final payload = entry.payload;
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final result = await _client
        .from('shopping_lists')
        .upsert({
          'id': entry.entityId,
          'home_id': payload['home_id'],
          'title': payload['title'],
          'type': payload['type'] ?? 'grocery',
          'icon': payload['icon'] ?? 'shopping_cart',
          'created_by': user.id,
        }, onConflict: 'id')
        .select('id')
        .maybeSingle();

    return result?['id'] as String?;
  }

  Future<void> _executeUpdateShoppingList(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    final payload = entry.payload;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': _client.auth.currentUser?.id,
    };

    if (payload['title'] != null) updates['title'] = payload['title'];
    if (payload['type'] != null) updates['type'] = payload['type'];
    if (payload['status'] != null) updates['status'] = payload['status'];

    await _client
        .from('shopping_lists')
        .update(updates)
        .eq('id', entry.entityId);
  }

  Future<String?> _executeAddItem(QueueEntry entry) async {
    final payload = entry.payload;
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final table = entry.entityType.tableName;
    // Use upsert with the pre-generated ID so that subsequent
    // update/delete/markPurchased entries referencing this ID work correctly
    final result = await _client
        .from(table)
        .upsert({
          'id': entry.entityId,
          'list_id': payload['list_id'],
          'name': payload['name'],
          'quantity': payload['quantity'] ?? 1,
          'unit_id': payload['unit_id'],
          'category_id': payload['category_id'],
          'estimated_price': payload['estimated_price'],
          'currency': payload['currency'],
          'note': payload['note'],
          'created_by': user.id,
          if (payload['status'] != null) 'status': payload['status'],
          if (entry.entityType == EntityType.shoppingItem &&
              payload['completed_at'] != null)
            'completed_at': payload['completed_at'],
          if (entry.entityType == EntityType.shoppingItem &&
              payload['completed_by'] != null)
            'completed_by': payload['completed_by'],
          if (payload['purchased_quantity'] != null)
            'purchased_quantity': payload['purchased_quantity'],
        }, onConflict: 'id')
        .select('id')
        .maybeSingle();

    return result?['id'] as String?;
  }

  Future<void> _executeUpdateItem(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    final payload = entry.payload;
    final table = entry.entityType.tableName;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': _client.auth.currentUser?.id,
    };

    if (payload['name'] != null) updates['name'] = payload['name'];
    if (payload['quantity'] != null) updates['quantity'] = payload['quantity'];
    if (payload['purchased_quantity'] != null) {
      updates['purchased_quantity'] = payload['purchased_quantity'];
    }
    if (payload.containsKey('unit_id')) updates['unit_id'] = payload['unit_id'];
    if (payload.containsKey('category_id')) {
      updates['category_id'] = payload['category_id'];
    }
    if (payload.containsKey('estimated_price')) {
      updates['estimated_price'] = payload['estimated_price'];
    } else if (payload.containsKey('price')) {
      updates['estimated_price'] = payload['price'];
    }
    if (payload.containsKey('note')) updates['note'] = payload['note'];
    if (payload['status'] != null) {
      updates['status'] = payload['status'];
      if (entry.entityType == EntityType.shoppingItem) {
        final isPurchased = payload['status'] == 'completed';
        if (isPurchased) {
          updates['completed_at'] =
              payload['completed_at'] ?? DateTime.now().toIso8601String();
          updates['completed_by'] =
              payload['completed_by'] ?? _client.auth.currentUser?.id;
        } else {
          updates['completed_at'] = null;
          updates['completed_by'] = null;
        }
      }
    }

    await _client.from(table).update(updates).eq('id', entry.entityId);
  }

  Future<void> _executeDeleteItem(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    final table = entry.entityType.tableName;
    await _client
        .from(table)
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': _client.auth.currentUser?.id,
        })
        .eq('id', entry.entityId);
  }

  Future<void> _executeRestoreItem(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    await _client.rpc(
      'restore_shopping_item',
      params: {'p_item_id': entry.entityId},
    );
  }

  Future<void> _executeMarkPurchased(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    final payload = entry.payload;
    final table = entry.entityType.tableName;
    final user = _client.auth.currentUser;

    final isPurchased = payload['status'] == 'completed';

    final updates = <String, dynamic>{
      'status': payload['status'] ?? (isPurchased ? 'completed' : 'pending'),
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': user?.id,
    };

    if (entry.entityType == EntityType.shoppingItem) {
      updates['completed_at'] = isPurchased
          ? (payload['completed_at'] ?? DateTime.now().toIso8601String())
          : null;
      updates['completed_by'] = isPurchased ? (user?.id) : null;
    }
    if (payload['purchased_quantity'] != null) {
      updates['purchased_quantity'] = payload['purchased_quantity'];
    }

    await _client.from(table).update(updates).eq('id', entry.entityId);
  }

  Future<void> _executeUpdateQuantity(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    final payload = entry.payload;
    final table = entry.entityType.tableName;

    await _client
        .from(table)
        .update({
          'quantity': payload['quantity'],
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': _client.auth.currentUser?.id,
        })
        .eq('id', entry.entityId);
  }

  Future<String?> _executeCreateCategory(QueueEntry entry) async {
    final payload = entry.payload;
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final result = await _client
        .from('categories')
        .upsert({
          'id': entry.entityId,
          'home_id': payload['home_id'] ?? entry.homeId,
          'name': payload['name'],
          'type': payload['type'] ?? 'shopping',
          'icon': payload['icon'],
          'color': payload['color'],
          'sort_order': payload['sort_order'] ?? 0,
          'is_default': false,
          'created_by': payload['created_by'] ?? user.id,
          if (payload['created_at'] != null)
            'created_at': payload['created_at'],
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id')
        .select()
        .maybeSingle();

    if (result != null) {
      await CategoriesDao(
        LocalDatabaseService.instance,
      ).upsertCategories([CategoryModel.fromJson(result)]);
      return result['id'] as String?;
    }
    return entry.entityId;
  }

  Future<void> _executeUpdateCategory(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    final payload = entry.payload;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (payload.containsKey('name')) updates['name'] = payload['name'];
    if (payload.containsKey('icon')) updates['icon'] = payload['icon'];
    if (payload.containsKey('color')) updates['color'] = payload['color'];
    if (payload.containsKey('sort_order')) {
      updates['sort_order'] = payload['sort_order'];
    }

    final result = await _client
        .from('categories')
        .update(updates)
        .eq('id', entry.entityId)
        .select()
        .maybeSingle();

    if (result != null) {
      await CategoriesDao(
        LocalDatabaseService.instance,
      ).upsertCategories([CategoryModel.fromJson(result)]);
    }
  }

  Future<void> _executeDeleteCategory(QueueEntry entry) async {
    await _assertBaseRevisionStillCurrent(entry);
    final deletedAt = DateTime.now();
    await _client
        .from('categories')
        .update({
          'deleted_at': deletedAt.toIso8601String(),
          'updated_at': deletedAt.toIso8601String(),
        })
        .eq('id', entry.entityId);
    await CategoriesDao(
      LocalDatabaseService.instance,
    ).softDeleteCategory(entry.entityId, deletedAt);
  }

  Future<String?> _executeCreateUnit(QueueEntry entry) async {
    final payload = entry.payload;
    final result = await _client
        .from('units')
        .upsert({
          'id': entry.entityId,
          'name': payload['name'],
          'symbol': payload['symbol'],
          'type': payload['type'] ?? 'count',
          'is_default': payload['is_default'] ?? false,
        }, onConflict: 'id')
        .select()
        .maybeSingle();

    if (result != null) {
      await UnitsDao(
        LocalDatabaseService.instance,
      ).upsertUnits([UnitModel.fromJson(result)]);
      return result['id'] as String?;
    }
    return entry.entityId;
  }

  Future<void> _executeUpdateUnit(QueueEntry entry) async {
    final payload = entry.payload;
    final updates = <String, dynamic>{};
    if (payload.containsKey('name')) updates['name'] = payload['name'];
    if (payload.containsKey('symbol')) updates['symbol'] = payload['symbol'];
    if (updates.isEmpty) return;

    final result = await _client
        .from('units')
        .update(updates)
        .eq('id', entry.entityId)
        .select()
        .maybeSingle();

    if (result != null) {
      await UnitsDao(
        LocalDatabaseService.instance,
      ).upsertUnits([UnitModel.fromJson(result)]);
    }
  }

  Future<void> _executeDeleteUnit(QueueEntry entry) async {
    await _client.from('units').delete().eq('id', entry.entityId);
    await UnitsDao(LocalDatabaseService.instance).deleteUnit(entry.entityId);
  }

  Future<String?> _executeStartShoppingModeSession(QueueEntry entry) async {
    final payload = entry.payload;
    final result = await _client
        .from('shopping_mode_sessions')
        .upsert({
          'id': entry.entityId,
          'shopping_list_id': payload['shopping_list_id'],
          'user_id': payload['user_id'],
          'home_id': payload['home_id'] ?? entry.homeId,
          'started_at':
              payload['started_at'] ?? DateTime.now().toIso8601String(),
          'items_total_count': payload['items_total_count'] ?? 0,
          'items_purchased_count': payload['items_purchased_count'] ?? 0,
        }, onConflict: 'id')
        .select()
        .maybeSingle();

    if (result != null) {
      await ShoppingModeSessionsDao(
        LocalDatabaseService.instance,
      ).upsertSession(ShoppingModeSessionModel.fromJson(result));
      return result['id'] as String?;
    }
    return entry.entityId;
  }

  Future<void> _executeEndShoppingModeSession(QueueEntry entry) async {
    final payload = entry.payload;
    final endedAt = _parseDateTime(payload['ended_at']) ?? DateTime.now();
    final result = await _client
        .from('shopping_mode_sessions')
        .update({
          'ended_at': endedAt.toIso8601String(),
          'items_purchased_count': payload['items_purchased_count'] ?? 0,
        })
        .eq('id', entry.entityId)
        .select()
        .maybeSingle();

    final dao = ShoppingModeSessionsDao(LocalDatabaseService.instance);
    if (result != null) {
      await dao.upsertSession(ShoppingModeSessionModel.fromJson(result));
    } else {
      await dao.endSessionLocally(
        sessionId: entry.entityId,
        itemsPurchasedCount: payload['items_purchased_count'] as int? ?? 0,
        endedAt: endedAt,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Notification actions
  // ---------------------------------------------------------------------------

  Future<String?> _executeNotificationAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.markNotificationRead:
        return _executeMarkNotificationRead(entry);
      case ActionType.markAllNotificationsRead:
        return _executeMarkAllNotificationsRead(entry);
      default:
        throw Exception(
          'Notification action not supported in offline queue: ${entry.actionType}',
        );
    }
  }

  Future<String?> _executeMarkNotificationRead(QueueEntry entry) async {
    final payload = entry.payload;
    final notificationIds = (payload['notification_ids'] as List?)
        ?.map((e) => e.toString())
        .toList();
    if (notificationIds == null || notificationIds.isEmpty) {
      return entry.entityId;
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .inFilter('id', notificationIds);

    final dao = NotificationsDao(LocalDatabaseService.instance);
    await dao.markAsRead(notificationIds);

    return entry.entityId;
  }

  Future<String?> _executeMarkAllNotificationsRead(QueueEntry entry) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);

    final dao = NotificationsDao(LocalDatabaseService.instance);
    await dao.markAllAsRead(user.id);

    return entry.entityId;
  }

  // ---------------------------------------------------------------------------
  // Notification Preference actions
  // ---------------------------------------------------------------------------

  Future<String?> _executeNotificationPreferenceAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.updateNotificationPreference:
        return _executeUpdateNotificationPreference(entry);
      default:
        throw Exception(
          'Notification preference action not supported: ${entry.actionType}',
        );
    }
  }

  Future<String?> _executeUpdateNotificationPreference(QueueEntry entry) async {
    final payload = entry.payload;
    final homeId = payload['home_id'] as String? ?? entry.homeId;
    final field = payload['field'] as String?;
    final value = payload['value'] as bool?;

    if (homeId == null || field == null || value == null) {
      throw Exception(
        'Missing required fields for notification preference update',
      );
    }

    await _client
        .from('notification_preferences')
        .upsert({
          'user_id': _client.auth.currentUser?.id,
          'home_id': homeId,
          field: value,
        }, onConflict: 'user_id,home_id')
        .select()
        .maybeSingle();

    final dao = NotificationPreferencesDao(LocalDatabaseService.instance);
    await dao.updateField(
      userId: _client.auth.currentUser?.id ?? '',
      homeId: homeId,
      field: field,
      value: value,
    );

    return entry.entityId;
  }

  // ---------------------------------------------------------------------------
  // Invitation actions
  // ---------------------------------------------------------------------------

  Future<String?> _executeInvitationAction(QueueEntry entry) async {
    switch (entry.actionType) {
      case ActionType.acceptInvitation:
        return _executeAcceptInvitation(entry);
      case ActionType.declineInvitation:
        return _executeDeclineInvitation(entry);
      case ActionType.cancelInvitation:
        return _executeCancelInvitation(entry);
      default:
        throw Exception(
          'Invitation action not supported in offline queue: ${entry.actionType}',
        );
    }
  }

  Future<String?> _executeAcceptInvitation(QueueEntry entry) async {
    final payload = entry.payload;
    final token = payload['token'] as String?;
    if (token == null) throw Exception('Missing invitation token');

    final response = await _client.rpc(
      'accept_invitation',
      params: {'invitation_token': token},
    );

    if (response != null) {
      final invitationData = response as Map<String, dynamic>;
      final invitationsDao = InvitationsDao(LocalDatabaseService.instance);
      await invitationsDao.updateStatus(
        invitationId: invitationData['id'] as String? ?? entry.entityId,
        status: 'accepted',
        acceptedAt: DateTime.now(),
      );
    }

    return entry.entityId;
  }

  Future<String?> _executeDeclineInvitation(QueueEntry entry) async {
    final payload = entry.payload;
    final token = payload['token'] as String?;
    if (token == null) throw Exception('Missing invitation token');

    final invitation = await _client
        .from('invitations')
        .select()
        .eq('token', token)
        .eq('status', 'pending')
        .maybeSingle();

    if (invitation != null) {
      await _client
          .from('invitations')
          .update({'status': 'cancelled'})
          .eq('id', invitation['id']);

      final invitationsDao = InvitationsDao(LocalDatabaseService.instance);
      await invitationsDao.updateStatus(
        invitationId: invitation['id'] as String,
        status: 'cancelled',
      );
    }

    return entry.entityId;
  }

  Future<String?> _executeCancelInvitation(QueueEntry entry) async {
    final invitationId = entry.entityId;

    await _client
        .from('invitations')
        .update({'status': 'cancelled'})
        .eq('id', invitationId);

    final invitationsDao = InvitationsDao(LocalDatabaseService.instance);
    await invitationsDao.updateStatus(
      invitationId: invitationId,
      status: 'cancelled',
    );

    return entry.entityId;
  }

  Future<void> _assertBaseRevisionStillCurrent(QueueEntry entry) async {
    final baseUpdatedAt = _baseUpdatedAt(entry.payload);
    if (baseUpdatedAt == null) return;

    final row = await _client
        .from(entry.entityType.tableName)
        .select('updated_at')
        .eq('id', entry.entityId)
        .maybeSingle();
    if (row == null) return;

    final remoteUpdatedAt = _parseDateTime(row['updated_at']);
    if (remoteUpdatedAt == null) return;

    if (remoteUpdatedAt.isAfter(baseUpdatedAt)) {
      throw Exception(
        'conflict: ${entry.entityType.tableName}/${entry.entityId} changed on server',
      );
    }
  }

  DateTime? _baseUpdatedAt(Map<String, dynamic> payload) {
    return _parseDateTime(
      payload['base_updated_at'] ?? payload['baseUpdatedAt'],
    );
  }

  DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
