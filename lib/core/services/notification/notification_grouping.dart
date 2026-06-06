import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationGroupInfo {
  final String groupKey;
  final String category;
  final String homeId;

  const NotificationGroupInfo({
    required this.groupKey,
    required this.category,
    required this.homeId,
  });
}

class NotificationGroupingHelper {
  static final Map<String, List<String>> groupMessages = {};

  static NotificationGroupInfo groupInfoForMessage(RemoteMessage message) {
    final homeId = message.data['home_id'] as String? ?? 'default';
    final category =
        message.data['category'] as String? ??
        message.data['event_type'] as String? ??
        'general';
    final groupKey =
        message.data['group'] as String? ?? 'sawa_${category}_$homeId';
    return NotificationGroupInfo(
      groupKey: groupKey,
      category: category,
      homeId: homeId,
    );
  }

  static Future<List<String>> appendGroupedMessage(
    String groupKey,
    String message,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'notification_group_$groupKey';
    final rawMessages = prefs.getString(storageKey);
    final storedMessages = rawMessages == null
        ? <String>[]
        : (jsonDecode(rawMessages) as List).cast<String>();

    final messages = [...storedMessages, message];
    final trimmedMessages = messages.length > 5
        ? messages.sublist(messages.length - 5)
        : messages;

    await prefs.setString(storageKey, jsonEncode(trimmedMessages));
    return trimmedMessages;
  }

  static int stableNotificationId(RemoteMessage message) {
    final notificationId = message.data['notification_id'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      return notificationId.hashCode.abs() % 100000;
    }
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }
}
