import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_preference.dart';
import '../models/notification_model.dart';
import '../models/notification_preference_model.dart';
import 'notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository(this._client);

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

    final response = await _client.rpc('get_notification_history', params: {
      'p_limit': limit,
      'p_offset': offset,
      'p_home_id': homeId,
      'p_category': category,
      'p_unread_only': unreadOnly,
    });

    return (response as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>).toEntity())
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

  @override
  Future<List<NotificationPreference>> getPreferences() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', user.id)
        .order('category');

    return (response as List)
        .map((json) =>
            NotificationPreferenceModel.fromJson(json as Map<String, dynamic>)
                .toEntity())
        .toList();
  }

  @override
  Future<List<NotificationPreference>> updatePreferences({
    required List<Map<String, dynamic>> preferences,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final results = <NotificationPreference>[];

    for (final pref in preferences) {
      final response = await _client
          .from('notification_preferences')
          .upsert({
            'user_id': user.id,
            'category': pref['category'],
            'enabled': pref['enabled'],
            'created_by': user.id,
          }, onConflict: 'user_id,category')
          .select()
          .single();

      results.add(
          NotificationPreferenceModel.fromJson(response).toEntity());
    }

    return results;
  }

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
}
