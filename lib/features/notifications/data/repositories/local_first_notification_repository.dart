import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/core/local_database/daos/notification_preferences_dao.dart';
import 'package:sawa/core/local_database/daos/notifications_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/local_database/local_model_mappers.dart';
import 'package:sawa/features/notifications/data/models/notification_model.dart';
import 'package:sawa/features/notifications/data/models/notification_preference_model.dart';
import 'package:sawa/features/notifications/domain/entities/notification.dart';
import 'package:sawa/features/notifications/domain/entities/notification_preference.dart';
import 'package:sawa/features/notifications/data/repositories/notification_repository.dart';
import 'package:sawa/features/offline_queue/data/datasources/queue_datasource.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:uuid/uuid.dart';

class LocalFirstNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;
  final NotificationsDao _notificationsDao;
  final NotificationPreferencesDao _preferencesDao;
  final QueueDataSource _queueDataSource;

  LocalFirstNotificationRepository({
    required SupabaseClient client,
    NotificationsDao? notificationsDao,
    NotificationPreferencesDao? preferencesDao,
    required QueueDataSource queueDataSource,
  }) : _client = client,
       _notificationsDao =
           notificationsDao ?? NotificationsDao(LocalDatabaseService.instance),
       _preferencesDao =
           preferencesDao ??
           NotificationPreferencesDao(LocalDatabaseService.instance),
       _queueDataSource = queueDataSource;

  String? get _userId => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Notification history
  // ---------------------------------------------------------------------------

  @override
  Future<List<AppNotification>> getNotificationHistory({
    int limit = 20,
    int offset = 0,
    String? homeId,
    String? category,
    bool unreadOnly = false,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Read from Drift first
    final localRows = await _notificationsDao.getNotifications(
      userId: userId,
      homeId: homeId,
      category: category,
      unreadOnly: unreadOnly,
      limit: limit,
      offset: offset,
    );

    // 2. Refresh from remote in background
    _refreshNotificationsFromRemote(
      userId: userId,
      homeId: homeId,
      category: category,
      unreadOnly: unreadOnly,
      limit: limit,
      offset: offset,
    );

    return localRows.map((row) => row.toAppNotification()).toList();
  }

  Future<void> _refreshNotificationsFromRemote({
    required String userId,
    String? homeId,
    String? category,
    bool unreadOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('notifications').select().eq('user_id', userId);

      if (homeId != null) query = query.eq('home_id', homeId);
      if (category != null) query = query.eq('category', category);
      if (unreadOnly) query = query.eq('is_read', false);

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final models = (response as List)
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      await _notificationsDao.upsertNotifications(
        models.map((m) => m.toLocalRow()).toList(),
      );
    } catch (_) {
      // Silent fail - local data is already returned
    }
  }

  // ---------------------------------------------------------------------------
  // Unread count
  // ---------------------------------------------------------------------------

  @override
  Future<int> getUnreadCount() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Read from Drift first
    final localCount = await _notificationsDao.getUnreadCount(userId);

    // 2. Refresh from remote in background
    _refreshUnreadCountFromRemote(userId);

    return localCount;
  }

  Future<void> _refreshUnreadCountFromRemote(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      // If count differs, refresh the full list
      final localCount = await _notificationsDao.getUnreadCount(userId);
      if (response.count != localCount) {
        await _refreshNotificationsFromRemote(
          userId: userId,
          unreadOnly: true,
          limit: 100,
        );
      }
    } catch (_) {
      // Silent fail
    }
  }

  // ---------------------------------------------------------------------------
  // Mark as read
  // ---------------------------------------------------------------------------

  @override
  Future<int> markAsRead(List<String> notificationIds) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Write to Drift immediately
    await _notificationsDao.markAsRead(notificationIds);

    // 2. Try Supabase
    try {
      final response = await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .inFilter('id', notificationIds)
          .select();
      return response.length;
    } catch (_) {
      // 3. Enqueue to outbox on failure
      await _queueDataSource.enqueueAction(
        actionType: ActionType.markNotificationRead,
        entityType: EntityType.notification,
        entityId: notificationIds.first,
        scope: MutationScope.user,
        payload: {'notification_ids': notificationIds},
      );
      return notificationIds.length;
    }
  }

  @override
  Future<int> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Write to Drift immediately
    await _notificationsDao.markAllAsRead(userId);

    // 2. Try Supabase
    try {
      final response = await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false)
          .select();
      return response.length;
    } catch (_) {
      // 3. Enqueue to outbox on failure
      await _queueDataSource.enqueueAction(
        actionType: ActionType.markAllNotificationsRead,
        entityType: EntityType.notification,
        entityId: userId,
        scope: MutationScope.user,
        payload: {'user_id': userId},
      );
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  @override
  Future<NotificationPreferences> getPreferences({
    required String homeId,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Read from Drift first
    final localPref = await _preferencesDao.getPreference(
      userId: userId,
      homeId: homeId,
    );

    if (localPref != null) {
      // 2. Refresh from remote in background
      _refreshPreferenceFromRemote(userId: userId, homeId: homeId);
      return localPref.toNotificationPreferences();
    }

    // 3. No local row - create default locally
    final defaultPref = _defaultPreferenceModel(userId: userId, homeId: homeId);
    await _preferencesDao.upsertPreference(defaultPref.toLocalRow());

    // 4. Try Supabase upsert in background
    _upsertDefaultPreferenceToRemote(userId: userId, homeId: homeId);

    return defaultPref.toEntity();
  }

  Future<void> _refreshPreferenceFromRemote({
    required String userId,
    required String homeId,
  }) async {
    try {
      final response = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .eq('home_id', homeId)
          .maybeSingle();

      if (response != null) {
        final model = NotificationPreferencesModel.fromJson(response);
        await _preferencesDao.upsertPreference(model.toLocalRow());
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _upsertDefaultPreferenceToRemote({
    required String userId,
    required String homeId,
  }) async {
    try {
      await _client
          .from('notification_preferences')
          .upsert({
            'user_id': userId,
            'home_id': homeId,
            'item_added': true,
            'item_completed': true,
            'low_stock': true,
            'expiry_alert': true,
            'expense_added': true,
            'task_assigned': true,
            'task_due': true,
          }, onConflict: 'user_id,home_id')
          .select()
          .maybeSingle();
    } catch (_) {
      // Silent fail - default is already saved locally
    }
  }

  @override
  Future<NotificationPreferences> updatePreference({
    required String homeId,
    required String field,
    required bool value,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    const allowedFields = {
      'item_added',
      'item_completed',
      'low_stock',
      'expiry_alert',
      'expense_added',
      'task_assigned',
      'task_due',
    };
    if (!allowedFields.contains(field)) {
      throw ArgumentError('Invalid field: $field');
    }

    // 1. Write to Drift immediately
    await _preferencesDao.updateField(
      userId: userId,
      homeId: homeId,
      field: field,
      value: value,
    );

    // 2. Try Supabase
    try {
      final response = await _client
          .from('notification_preferences')
          .upsert({
            'user_id': userId,
            'home_id': homeId,
            field: value,
          }, onConflict: 'user_id,home_id')
          .select()
          .maybeSingle();

      if (response != null) {
        final model = NotificationPreferencesModel.fromJson(response);
        await _preferencesDao.upsertPreference(model.toLocalRow());
        return model.toEntity();
      }
    } catch (_) {
      // 3. Enqueue to outbox on failure
      await _queueDataSource.enqueueAction(
        actionType: ActionType.updateNotificationPreference,
        entityType: EntityType.notificationPreference,
        entityId: '${userId}_$homeId',
        homeId: homeId,
        scope: MutationScope.user,
        payload: {'home_id': homeId, 'field': field, 'value': value},
      );
    }

    // Return the local state
    final localPref = await _preferencesDao.getPreference(
      userId: userId,
      homeId: homeId,
    );
    return localPref?.toNotificationPreferences() ??
        _defaultPreferenceModel(userId: userId, homeId: homeId).toEntity();
  }

  // ---------------------------------------------------------------------------
  // Send notification (passthrough to Edge Function)
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendNotification({
    required String eventType,
    required String homeId,
    required String actorId,
    required String referenceId,
    required String referenceType,
    Map<String, dynamic>? context,
  }) async {
    await _client.functions.invoke(
      'send-notification',
      body: {
        'event_type': eventType,
        'home_id': homeId,
        'actor_id': actorId,
        'reference_id': referenceId,
        'reference_type': referenceType,
        'context': context ?? {},
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  NotificationPreferencesModel _defaultPreferenceModel({
    required String userId,
    required String homeId,
  }) {
    final now = DateTime.now();
    return NotificationPreferencesModel(
      id: const Uuid().v4(),
      userId: userId,
      homeId: homeId,
      itemAdded: true,
      itemCompleted: true,
      lowStock: true,
      expiryAlert: true,
      expenseAdded: true,
      taskDue: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}
