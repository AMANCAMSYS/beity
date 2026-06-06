import '../supabase_service.dart';
import '../app_logger.dart';

class NotificationSender {
  static Future<void> invokeSendNotification({
    required String debugEventName,
    required Map<String, dynamic> body,
  }) async {
    final response = await SupabaseService.client.functions.invoke(
      'send-notification',
      body: body,
    );

    final data = response.data;
    if (data is Map) {
      final fcmTokensSent = data['fcm_tokens_sent'];
      final recipients = data['recipients'];
      if (fcmTokensSent == 0) {
        AppLogger.i(
          'send-notification:$debugEventName completed without FCM delivery. '
          'recipients=$recipients data=$data',
        );
      }
      return;
    }

    AppLogger.i(
      'send-notification:$debugEventName returned unexpected response: $data',
    );
  }

  static Future<void> sendShoppingListNotification({
    required String homeId,
    required String actorId,
    required String referenceId,
    required String eventType,
    required Map<String, dynamic> context,
  }) async {
    try {
      await invokeSendNotification(
        debugEventName: eventType,
        body: {
          'event_type': eventType,
          'home_id': homeId,
          'actor_id': actorId,
          'reference_id': referenceId,
          'reference_type': 'shopping_list',
          'context': context,
        },
      );
    } catch (e) {
      AppLogger.i('Error sending shopping list notification: $e');
    }
  }

  static Future<void> sendExpenseNotification({
    required String homeId,
    required String actorId,
    required String expenseId,
    required String eventType,
    required Map<String, dynamic> context,
    List<String>? targetUserIds,
  }) async {
    try {
      await invokeSendNotification(
        debugEventName: eventType,
        body: {
          'event_type': eventType,
          'home_id': homeId,
          'actor_id': actorId,
          'reference_id': expenseId,
          'reference_type': eventType == 'expense_settled'
              ? 'settlement'
              : 'expense',
          'context': context,
          if (targetUserIds != null && targetUserIds.isNotEmpty)
            'target_user_ids': targetUserIds,
        },
      );
    } catch (e) {
      AppLogger.i('Error sending expense notification: $e');
    }
  }

  static Future<void> sendInventoryNotification({
    required String homeId,
    required String actorId,
    required String inventoryItemId,
    required String eventType,
    required Map<String, dynamic> context,
  }) async {
    try {
      await invokeSendNotification(
        debugEventName: eventType,
        body: {
          'event_type': eventType,
          'home_id': homeId,
          'actor_id': actorId,
          'reference_id': inventoryItemId,
          'reference_type': 'inventory_item',
          'context': context,
        },
      );
    } catch (e) {
      AppLogger.i('Error sending inventory notification: $e');
    }
  }

  static Future<void> sendTaskAssignedNotification({
    required String homeId,
    required String actorId,
    required String taskId,
    required String targetUserId,
    required String taskTitle,
  }) async {
    try {
      await invokeSendNotification(
        debugEventName: 'task_assigned',
        body: {
          'event_type': 'task_assigned',
          'home_id': homeId,
          'actor_id': actorId,
          'target_user_id': targetUserId,
          'reference_id': taskId,
          'reference_type': 'task',
          'context': {'task_title': taskTitle},
        },
      );
    } catch (e) {
      AppLogger.i('Error sending task assignment notification: $e');
    }
  }

  static Future<void> sendMemberJoinedNotification({
    required String homeId,
    required String actorId,
    required Map<String, dynamic> context,
  }) async {
    try {
      await invokeSendNotification(
        debugEventName: 'member_joined',
        body: {
          'event_type': 'member_joined',
          'home_id': homeId,
          'actor_id': actorId,
          'reference_id': homeId,
          'reference_type': 'home',
          'context': context,
        },
      );
    } catch (e) {
      AppLogger.i('Error sending member joined notification: $e');
    }
  }
}
