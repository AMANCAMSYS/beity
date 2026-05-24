import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_preference.dart';

abstract class NotificationRepository {
  /// Get paginated notification history for the current user
  Future<List<AppNotification>> getNotificationHistory({
    int limit = 20,
    int offset = 0,
    String? homeId,
    String? category,
    bool unreadOnly = false,
  });

  /// Get unread notification count for the current user
  Future<int> getUnreadCount();

  /// Mark specific notifications as read
  Future<int> markAsRead(List<String> notificationIds);

  /// Mark all notifications as read
  Future<int> markAllAsRead();

  /// Get notification preferences for the current user and home
  Future<NotificationPreferences> getPreferences({required String homeId});

  /// Update a single notification preference field
  Future<NotificationPreferences> updatePreference({
    required String homeId,
    required String field,
    required bool value,
  });

  /// Send a notification via Edge Function (for client-triggered notifications)
  Future<void> sendNotification({
    required String eventType,
    required String homeId,
    required String actorId,
    required String referenceId,
    required String referenceType,
    Map<String, dynamic>? context,
  });
}
