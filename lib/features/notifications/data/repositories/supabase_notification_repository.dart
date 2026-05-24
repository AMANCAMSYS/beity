import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_preference.dart';
import '../models/notification_model.dart';
import '../models/notification_preference_model.dart';
import 'notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository(this._client);

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
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    var query = _client
        .from('notifications')
        .select()
        .eq('user_id', user.id);

    if (homeId != null) {
      query = query.eq('home_id', homeId);
    }

    if (category != null) {
      query = query.eq('category', category);
    }

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) =>
            NotificationModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false)
        .count(CountOption.exact);

    return response.count;
  }

  @override
  Future<int> markAsRead(List<String> notificationIds) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .inFilter('id', notificationIds)
        .select();

    return response.length;
  }

  @override
  Future<int> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false)
        .select();

    return response.length;
  }

  // ---------------------------------------------------------------------------
  // Notification preferences
  // ---------------------------------------------------------------------------

  @override
  Future<NotificationPreferences> getPreferences({required String homeId}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    try {
      final response = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .eq('home_id', homeId)
          .maybeSingle();

      if (response == null) {
        // No row yet — upsert defaults so the UI can immediately toggle them.
        final created = await _client
            .from('notification_preferences')
            .upsert(
              {
                'user_id': user.id,
                'home_id': homeId,
                'item_added': true,
                'item_completed': true,
                'low_stock': true,
                'expiry_alert': true,
                'expense_added': true,
                'task_due': true,
              },
              onConflict: 'user_id,home_id',
            )
            .select()
            .maybeSingle();

        if (created == null) {
          // DB unreachable — return safe in-memory defaults.
          return _defaultPrefs(userId: user.id, homeId: homeId);
        }
        return NotificationPreferencesModel.fromJson(created).toEntity();
      }

      return NotificationPreferencesModel.fromJson(response).toEntity();
    } catch (_) {
      // On any DB/parse error return safe defaults — never crash the UI.
      return _defaultPrefs(userId: user.id, homeId: homeId);
    }
  }

  @override
  Future<NotificationPreferences> updatePreference({
    required String homeId,
    required String field,
    required bool value,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    // Allowlist of valid column names — prevents arbitrary column injection.
    const allowedFields = {
      'item_added',
      'item_completed',
      'low_stock',
      'expiry_alert',
      'expense_added',
      'task_due',
    };
    if (!allowedFields.contains(field)) {
      throw ArgumentError('حقل غير مسموح به: $field');
    }

    try {
      // Upsert so we never crash when the row doesn't exist yet.
      final response = await _client
          .from('notification_preferences')
          .upsert(
            {
              'user_id': user.id,
              'home_id': homeId,
              field: value,
            },
            onConflict: 'user_id,home_id',
          )
          .select()
          .maybeSingle();

      if (response == null) {
        return _defaultPrefs(userId: user.id, homeId: homeId);
      }
      return NotificationPreferencesModel.fromJson(response).toEntity();
    } catch (_) {
      return _defaultPrefs(userId: user.id, homeId: homeId);
    }
  }

  // ---------------------------------------------------------------------------
  // Edge Function trigger
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
    await _client.functions.invoke('send-notification', body: {
      'event_type': eventType,
      'home_id': homeId,
      'actor_id': actorId,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'context': context ?? {},
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  NotificationPreferences _defaultPrefs({
    required String userId,
    required String homeId,
  }) {
    return NotificationPreferences(
      id: '',
      userId: userId,
      homeId: homeId,
      itemAdded: true,
      itemCompleted: true,
      lowStock: true,
      expiryAlert: true,
      expenseAdded: true,
      taskDue: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
