import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../shared_prefs_provider.dart';
import '../../localization/app_localizations.dart';
import 'notification_grouping.dart';
import 'notification_initialization.dart';

class NotificationDisplayHelper {
  static bool isPurchaseEvent(String? eventType) {
    return eventType == 'item_completed' || eventType == 'item_uncompleted';
  }

  static bool shouldSuppressPurchaseNotification(String? eventType) {
    if (!isPurchaseEvent(eventType)) return false;
    final prefs = AppPreferences.instance;
    final purchaseNotificationsEnabled =
        prefs.getBool('settings.purchase_notifications') ?? true;
    return !purchaseNotificationsEnabled;
  }

  static Future<void> showLocalNotification(
    RemoteMessage message, {
    bool isBackground = false,
  }) async {
    final notification = message.notification;
    final String title =
        notification?.title ?? message.data['title'] ?? 'Notification';
    final String body = notification?.body ?? message.data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final groupInfo = NotificationGroupingHelper.groupInfoForMessage(message);
    final String groupKey = groupInfo.groupKey;
    final isQuiet = message.data['quiet'] == 'true';

    final androidDetails = AndroidNotificationDetails(
      'sawa_notifications',
      'SAWA Notifications',
      channelDescription: 'Notifications for shopping list and home activity',
      importance: isQuiet ? Importance.defaultImportance : Importance.max,
      priority: isQuiet ? Priority.defaultPriority : Priority.high,
      playSound: !isQuiet,
      enableVibration: !isQuiet,
      groupKey: groupKey,
      setAsGroupSummary: false,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      icon: '@mipmap/launcher_icon',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: !isQuiet,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final int notificationId = NotificationGroupingHelper.stableNotificationId(
      message,
    );

    await NotificationInitializer.localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: message.data['route'] as String?,
    );

    await _showGroupSummary(groupInfo, title, body);
  }

  static Future<void> _showGroupSummary(
    NotificationGroupInfo groupInfo,
    String latestTitle,
    String latestBody,
  ) async {
    final groupKey = groupInfo.groupKey;

    final messages = await NotificationGroupingHelper.appendGroupedMessage(
      groupKey,
      '$latestTitle: $latestBody',
    );
    NotificationGroupingHelper.groupMessages[groupKey] = messages;

    final messageCount = messages.length;
    final summaryTitle = _summaryTitleForGroup(groupInfo, messageCount);
    final summaryBody = _summaryBodyForGroup(groupInfo, messageCount);

    final summaryAndroid = AndroidNotificationDetails(
      'sawa_notifications',
      'SAWA Notifications',
      channelDescription: 'Notifications for shopping list and home activity',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
      groupKey: groupKey,
      setAsGroupSummary: true,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      icon: '@mipmap/launcher_icon',
      styleInformation: InboxStyleInformation(
        messages,
        contentTitle: summaryTitle,
        summaryText: summaryBody,
      ),
    );

    final summaryDetails = NotificationDetails(
      android: summaryAndroid,
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
      ),
    );

    final int summaryId = groupKey.hashCode.abs() % 100000;

    await NotificationInitializer.localNotifications.show(
      id: summaryId,
      title: summaryTitle,
      body: summaryBody,
      notificationDetails: summaryDetails,
    );
  }

  static String _getTranslated(String key, {Map<String, String>? arguments}) {
    final prefs = AppPreferences.instance;
    final lang = prefs.getString('settings.locale') ?? 'ar';
    return AppLocalizations(Locale(lang)).translate(key, arguments: arguments);
  }

  static String _summaryTitleForGroup(
    NotificationGroupInfo groupInfo,
    int messageCount,
  ) {
    if (groupInfo.category == 'task' || groupInfo.category == 'task_assigned') {
      return _getTranslated('notification_group_tasks_summary_title');
    }
    return 'SAWA';
  }

  static String _summaryBodyForGroup(
    NotificationGroupInfo groupInfo,
    int messageCount,
  ) {
    if (groupInfo.category == 'task' || groupInfo.category == 'task_assigned') {
      return _getTranslated(
        'notification_group_tasks_summary_body',
        arguments: {'count': messageCount.toString()},
      );
    }
    return _getTranslated(
      'notification_group_general_summary_body',
      arguments: {'count': messageCount.toString()},
    );
  }
}
