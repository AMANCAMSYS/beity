import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_logger.dart';

class NotificationInitializer {
  static final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool localNotificationsInitialized = false;

  static Future<void> requestPermission(FirebaseMessaging messaging) async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      AppLogger.i('Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      AppLogger.i('Error requesting notification permission: $e');
    }
  }

  static Future<void> initializeLocalNotifications({
    bool requestAndroidPermission = true,
    void Function(String)? onNotificationTap,
  }) async {
    if (localNotificationsInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && onNotificationTap != null) {
          onNotificationTap(details.payload!);
        }
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'sawa_notifications',
            'SAWA Notifications',
            description: 'Notifications for shopping list and home activity',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );

        if (!requestAndroidPermission) {
          localNotificationsInitialized = true;
          return;
        }

        try {
          final notificationsEnabled = await androidImplementation
              .areNotificationsEnabled();
          if (notificationsEnabled == false) {
            final granted = await androidImplementation
                .requestNotificationsPermission();
            if (granted == false) {
              AppLogger.i('Android notification permission was not granted.');
            }
          }
        } catch (e) {
          AppLogger.i('Unable to check Android notification permission: $e');
        }
      }
    }

    localNotificationsInitialized = true;
  }
}
