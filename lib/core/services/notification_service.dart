import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'app_logger.dart';
import 'notification/notification_initialization.dart';
import 'notification/notification_display.dart';
import 'notification/notification_navigation.dart';
import 'notification/notification_token_manager.dart';
import 'notification/notification_sender.dart';

@pragma('vm:entry-point')
Future<void> sawaFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await NotificationService.handleBackgroundMessage(message);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final Completer<bool> _readyCompleter = Completer<bool>();
  static bool _messageHandlersRegistered = false;

  static final Set<String> _activeScreenSubscriptions = {};

  static GlobalKey<NavigatorState>? _navigatorKey;

  static String? initialRoute;
  static bool pendingRouteNavigationScheduled = false;

  static String? get fcmToken => NotificationTokenManager.fcmToken;
  static Future<bool> get ready => _readyCompleter.future;

  static void _completeReady(bool value) {
    AppLogger.i('NotificationService ready: $value');
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete(value);
    }
  }

  static void markInitializationFailed() {
    _completeReady(false);
  }

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    NotificationNavigationHelper.schedulePendingRouteNavigation(_navigatorKey);
  }

  static void addActiveScreenSubscription(String route) {
    _activeScreenSubscriptions.add(route);
  }

  static void removeActiveScreenSubscription(String route) {
    _activeScreenSubscriptions.remove(route);
  }

  static bool isScreenActive(String? route) {
    if (route == null) return false;
    final normalizedRoute = _normalizeRouteForSuppression(route);
    return _activeScreenSubscriptions.any((activeRoute) {
      final normalizedActiveRoute = _normalizeRouteForSuppression(activeRoute);
      return normalizedRoute == normalizedActiveRoute ||
          normalizedRoute.startsWith('$normalizedActiveRoute/') ||
          normalizedActiveRoute.startsWith('$normalizedRoute/');
    });
  }

  static String _normalizeRouteForSuppression(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return route;
    return uri.path.isEmpty ? route : uri.path;
  }

  static Future<void> initialize() async {
    try {
      await NotificationInitializer.requestPermission(_messaging);

      await NotificationInitializer.initializeLocalNotifications(
        onNotificationTap: (payload) =>
            NotificationNavigationHelper.navigateToRoute(
              payload,
              _navigatorKey,
            ),
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _registerMessageHandlers();

      await NotificationTokenManager.refreshToken();

      AppLogger.i('NotificationService initialized successfully');

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      final launchDetails = await NotificationInitializer.localNotifications
          .getNotificationAppLaunchDetails();
      final launchPayload = launchDetails?.notificationResponse?.payload;
      if (launchPayload != null) {
        NotificationNavigationHelper.navigateToRoute(
          launchPayload,
          _navigatorKey,
        );
      }

      _completeReady(true);
    } catch (_) {
      AppLogger.i('NotificationService initialization failed');
      _completeReady(false);
      rethrow;
    }
  }

  static void _registerMessageHandlers() {
    if (_messageHandlersRegistered) return;

    _messaging.onTokenRefresh.listen((token) {
      NotificationTokenManager.saveTokenToSupabase(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onBackgroundMessage(
      sawaFirebaseMessagingBackgroundHandler,
    );

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    _messageHandlersRegistered = true;
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final route = message.data['route'] as String?;
    final eventType = message.data['event_type'] as String?;

    if (isScreenActive(route)) {
      return;
    }

    if (NotificationDisplayHelper.shouldSuppressPurchaseNotification(
      eventType,
    )) {
      return;
    }

    NotificationDisplayHelper.showLocalNotification(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    NotificationNavigationHelper.handleNotificationTap(
      message.data,
      _navigatorKey,
    );
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final route = message.data['route'] as String?;
    if (route != null && route.startsWith('/')) {
      initialRoute = route;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await NotificationInitializer.initializeLocalNotifications(
        requestAndroidPermission: false,
      );
      await NotificationDisplayHelper.showLocalNotification(
        message,
        isBackground: true,
      );
    }

    AppLogger.i('Background message received: ${message.messageId}');
  }

  static Future<void> refreshToken() => NotificationTokenManager.refreshToken();

  static Future<void> removeToken() => NotificationTokenManager.removeToken();

  static Future<void> sendShoppingListNotification({
    required String homeId,
    required String actorId,
    required String referenceId,
    required String eventType,
    required Map<String, dynamic> context,
  }) => NotificationSender.sendShoppingListNotification(
    homeId: homeId,
    actorId: actorId,
    referenceId: referenceId,
    eventType: eventType,
    context: context,
  );

  static Future<void> sendExpenseNotification({
    required String homeId,
    required String actorId,
    required String expenseId,
    required String eventType,
    required Map<String, dynamic> context,
    List<String>? targetUserIds,
  }) => NotificationSender.sendExpenseNotification(
    homeId: homeId,
    actorId: actorId,
    expenseId: expenseId,
    eventType: eventType,
    context: context,
    targetUserIds: targetUserIds,
  );

  static Future<void> sendInventoryNotification({
    required String homeId,
    required String actorId,
    required String inventoryItemId,
    required String eventType,
    required Map<String, dynamic> context,
  }) => NotificationSender.sendInventoryNotification(
    homeId: homeId,
    actorId: actorId,
    inventoryItemId: inventoryItemId,
    eventType: eventType,
    context: context,
  );

  static Future<void> sendTaskAssignedNotification({
    required String homeId,
    required String actorId,
    required String taskId,
    required String targetUserId,
    required String taskTitle,
  }) => NotificationSender.sendTaskAssignedNotification(
    homeId: homeId,
    actorId: actorId,
    taskId: taskId,
    targetUserId: targetUserId,
    taskTitle: taskTitle,
  );

  static Future<void> sendMemberJoinedNotification({
    required String homeId,
    required String actorId,
    required Map<String, dynamic> context,
  }) => NotificationSender.sendMemberJoinedNotification(
    homeId: homeId,
    actorId: actorId,
    context: context,
  );
}
