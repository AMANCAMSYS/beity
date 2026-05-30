import 'dart:async';
import 'package:beity/core/services/supabase_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/env_config.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static String? _fcmToken;

  // Active screen subscriptions for suppression
  static final Set<String> _activeScreenSubscriptions = {};

  static GlobalKey<NavigatorState>? _navigatorKey;
  
  // Store route if app is launched from terminated state before UI mounts
  static String? initialRoute;

  static String? get fcmToken => _fcmToken;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static void addActiveScreenSubscription(String route) {
    _activeScreenSubscriptions.add(route);
  }

  static void removeActiveScreenSubscription(String route) {
    _activeScreenSubscriptions.remove(route);
  }

  static bool isScreenActive(String? route) {
    if (route == null) return false;
    return _activeScreenSubscriptions.contains(route);
  }

  static Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure foreground notification options for iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final vapidKey = kIsWeb ? EnvConfig.firebaseVapidKey : null;
      _fcmToken = await _messaging.getToken(
        vapidKey: vapidKey?.isNotEmpty == true ? vapidKey : null,
      );

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _saveTokenToSupabase(token);
      });

      // Save initial token
      if (_fcmToken != null) {
        await _saveTokenToSupabase(_fcmToken!);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _navigateToRoute(details.payload!);
        }
      },
    );

    // Create custom notification channel on Android for heads-up notifications
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'beity_notifications',
            'Beity Notifications',
            description: 'Notifications for shopping list and home activity',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    try {
      await SupabaseService.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': _getPlatform(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
    } catch (e) {
      // Silently handle token save errors
    }
  }

  static String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'web';
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final route = message.data['route'] as String?;

    // Suppress notification if user is viewing the relevant screen
    if (isScreenActive(route)) {
      // Still record in history (server-side handles this)
      // Skip local notification display
      return;
    }

    // Show local notification
    _showLocalNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final String title = notification?.title ?? message.data['title'] ?? 'Notification';
    final String body = notification?.body ?? message.data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'beity_notifications',
      'Beity Notifications',
      channelDescription: 'Notifications for shopping list and home activity',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode != 0 ? notification.hashCode : DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: message.data['route'] as String?,
    );
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Background messages are handled by FCM automatically
    // The notification will be displayed by the system tray
    // We just need to handle the data payload when user taps
    debugPrint('Background message received: ${message.messageId}');
    
    // Store the notification data for when app opens
    // This is handled by getInitialMessage() in initialize()
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null) {
      _navigateToRoute(route);
    }
  }

  static void _navigateToRoute(String route) {
    if (route.isEmpty || !route.startsWith('/')) return;
    
    if (_navigatorKey?.currentContext != null) {
      GoRouter.of(_navigatorKey!.currentContext!).go(route);
    } else {
      // Store the route to be used as initialLocation by GoRouter
      initialRoute = route;
    }
  }

  /// Refresh FCM token - call this after user logs in
  static Future<void> refreshToken() async {
    try {
      final vapidKey = kIsWeb ? EnvConfig.firebaseVapidKey : null;
      _fcmToken = await _messaging.getToken(
        vapidKey: vapidKey?.isNotEmpty == true ? vapidKey : null,
      );

      if (_fcmToken != null) {
        await _saveTokenToSupabase(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
    }
  }

  /// Remove FCM token - call this when user logs out
  static Future<void> removeToken() async {
    try {
      if (_fcmToken != null) {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          await SupabaseService.client
              .from('device_tokens')
              .delete()
              .eq('user_id', user.id)
              .eq('token', _fcmToken!);
        }
      }
      _fcmToken = null;
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  static Future<void> sendShoppingListNotification({
    required String homeId,
    required String actorId,
    required String referenceId,
    required String eventType,
    required Map<String, dynamic> context,
  }) async {
    try {
      await SupabaseService.client.functions.invoke('send-notification', body: {
        'event_type': eventType,
        'home_id': homeId,
        'actor_id': actorId,
        'reference_id': referenceId,
        'reference_type': 'shopping_list',
        'context': context,
      });
    } catch (e) {
      debugPrint('Error sending shopping list notification: $e');
    }
  }

  static Future<void> sendInvitationNotification({
    required String homeId,
    required String actorId,
    required String invitationId,
    required Map<String, dynamic> context,
  }) async {
    try {
      await SupabaseService.client.functions.invoke('send-notification', body: {
        'event_type': 'invitation_received',
        'home_id': homeId,
        'actor_id': actorId,
        'reference_id': invitationId,
        'reference_type': 'invitation',
        'context': context,
      });
    } catch (e) {
      debugPrint('Error sending invitation notification: $e');
    }
  }

  static Future<void> sendMemberJoinedNotification({
    required String homeId,
    required String actorId,
    required Map<String, dynamic> context,
  }) async {
    try {
      await SupabaseService.client.functions.invoke('send-notification', body: {
        'event_type': 'member_joined',
        'home_id': homeId,
        'actor_id': actorId,
        'reference_id': homeId,
        'reference_type': 'home',
        'context': context,
      });
    } catch (e) {
      debugPrint('Error sending member joined notification: $e');
    }
  }
}
