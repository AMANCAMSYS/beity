import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:sawa/core/services/supabase_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config/env_config.dart';
import '../../firebase_options.dart';
import 'app_logger.dart';
import 'shared_prefs_provider.dart';
import '../localization/app_localizations.dart';

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
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static String? _fcmToken;
  static final Completer<bool> _readyCompleter = Completer<bool>();
  static bool _messageHandlersRegistered = false;
  static bool _localNotificationsInitialized = false;

  // Active screen subscriptions for suppression
  static final Set<String> _activeScreenSubscriptions = {};

  static GlobalKey<NavigatorState>? _navigatorKey;

  // Store route if app is launched from terminated state before UI mounts
  static String? initialRoute;
  static bool _pendingRouteNavigationScheduled = false;

  static String? get fcmToken => _fcmToken;
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
    _schedulePendingRouteNavigation();
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
      // Request permission FIRST before anything else
      try {
        final settings = await _messaging.requestPermission(
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

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure foreground notification options for iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _registerMessageHandlers();

      await refreshToken();

      AppLogger.i('NotificationService initialized successfully');

      // Handle notification tap when app is terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      final launchPayload = launchDetails?.notificationResponse?.payload;
      if (launchPayload != null) {
        _navigateToRoute(launchPayload);
      }

      _completeReady(true);
    } catch (_) {
      AppLogger.i('NotificationService initialization failed');
      _completeReady(false);
      rethrow;
    }
  }

  static Future<void> _initializeLocalNotifications({
    bool requestAndroidPermission = true,
  }) async {
    if (_localNotificationsInitialized) return;

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
          _localNotificationsInitialized = true;
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

    _localNotificationsInitialized = true;
  }

  static void _registerMessageHandlers() {
    if (_messageHandlersRegistered) return;

    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      unawaited(_saveTokenToSupabase(token));
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(
      sawaFirebaseMessagingBackgroundHandler,
    );

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    _messageHandlersRegistered = true;
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      AppLogger.i('Cannot save FCM token: user is null');
      return;
    }

    try {
      AppLogger.i('Saving FCM token for user: ${user.id}');
      await SupabaseService.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': _getPlatform(),
        'is_active': true,
        'created_by': user.id,
        'updated_by': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
      AppLogger.i('FCM token saved successfully');
    } catch (e) {
      AppLogger.i('Error saving FCM token to Supabase: $e');
    }
  }

  static String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'web';
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final route = message.data['route'] as String?;
    final eventType = message.data['event_type'] as String?;

    // Suppress notification if user is viewing the relevant screen
    if (isScreenActive(route)) {
      return;
    }

    // Check if purchase notifications are disabled
    if (_isPurchaseEvent(eventType)) {
      // Read the setting from SharedPreferences directly since we can't access Riverpod here
      final prefs = AppPreferences.instance;
      final purchaseNotificationsEnabled =
          prefs.getBool('settings.purchase_notifications') ?? true;
      if (!purchaseNotificationsEnabled) {
        return;
      }
    }

    // Show local notification
    _showLocalNotification(message);
  }

  static bool _isPurchaseEvent(String? eventType) {
    return eventType == 'item_completed' || eventType == 'item_uncompleted';
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final String title =
        notification?.title ?? message.data['title'] ?? 'Notification';
    final String body = notification?.body ?? message.data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final groupInfo = _groupInfoForMessage(message);
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

    final int notificationId = _stableNotificationId(message);

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: message.data['route'] as String?,
    );

    // Create/update group summary notification
    await _showGroupSummary(groupInfo, title, body);
  }

  static int _stableNotificationId(RemoteMessage message) {
    final notificationId = message.data['notification_id'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      return notificationId.hashCode.abs() % 100000;
    }
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  static final Map<String, List<String>> _groupMessages = {};

  static Future<void> _showGroupSummary(
    _NotificationGroupInfo groupInfo,
    String latestTitle,
    String latestBody,
  ) async {
    final groupKey = groupInfo.groupKey;

    // Track messages for this group
    final messages = await _appendGroupedMessage(
      groupKey,
      '$latestTitle: $latestBody',
    );
    _groupMessages[groupKey] = messages;

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

    // Use a consistent ID for the summary based on groupKey.
    final int summaryId = groupKey.hashCode.abs() % 100000;

    await _localNotifications.show(
      id: summaryId,
      title: summaryTitle,
      body: summaryBody,
      notificationDetails: summaryDetails,
    );
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final route = message.data['route'] as String?;
    if (route != null && route.startsWith('/')) {
      initialRoute = route;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _initializeLocalNotifications(requestAndroidPermission: false);
      await _showLocalNotification(message);
    }

    AppLogger.i('Background message received: ${message.messageId}');
  }

  static _NotificationGroupInfo _groupInfoForMessage(RemoteMessage message) {
    final homeId = message.data['home_id'] as String? ?? 'default';
    final category =
        message.data['category'] as String? ??
        message.data['event_type'] as String? ??
        'general';
    final groupKey =
        message.data['group'] as String? ?? 'sawa_${category}_$homeId';
    return _NotificationGroupInfo(
      groupKey: groupKey,
      category: category,
      homeId: homeId,
    );
  }

  static Future<List<String>> _appendGroupedMessage(
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

  static String _getTranslated(String key, {Map<String, String>? arguments}) {
    final prefs = AppPreferences.instance;
    final lang = prefs.getString('settings.locale') ?? 'ar';
    return AppLocalizations(Locale(lang)).translate(key, arguments: arguments);
  }

  static String _summaryTitleForGroup(
    _NotificationGroupInfo groupInfo,
    int messageCount,
  ) {
    if (groupInfo.category == 'task' || groupInfo.category == 'task_assigned') {
      return _getTranslated('notification_group_tasks_summary_title');
    }
    return 'SAWA';
  }

  static String _summaryBodyForGroup(
    _NotificationGroupInfo groupInfo,
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
      if (initialRoute == route) {
        initialRoute = null;
      }
    } else {
      // Store the route to be used as initialLocation by GoRouter
      initialRoute = route;
      _schedulePendingRouteNavigation();
    }
  }

  static void _schedulePendingRouteNavigation() {
    if (_pendingRouteNavigationScheduled || initialRoute == null) return;
    _pendingRouteNavigationScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingRouteNavigationScheduled = false;

      final route = initialRoute;
      final context = _navigatorKey?.currentContext;
      if (route == null || context == null) {
        if (initialRoute != null) {
          _schedulePendingRouteNavigation();
        }
        return;
      }

      initialRoute = null;
      GoRouter.of(context).go(route);
    });
  }

  /// Refresh FCM token - call this after user logs in
  static Future<void> refreshToken() async {
    try {
      final vapidKey = kIsWeb ? EnvConfig.firebaseVapidKey : null;
      _fcmToken = await _messaging.getToken(
        vapidKey: vapidKey?.isNotEmpty == true ? vapidKey : null,
      );

      AppLogger.i(
        'FCM Token obtained: ${_fcmToken != null ? "YES (${_fcmToken!.substring(0, 20)}...)" : "NULL"}',
      );

      if (_fcmToken != null) {
        await _saveTokenToSupabase(_fcmToken!);
      }
    } catch (e) {
      AppLogger.i('Error refreshing FCM token: $e');
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
              .update({
                'is_active': false,
                'updated_by': user.id,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', user.id)
              .eq('token', _fcmToken!);
        }
      }
      _fcmToken = null;
    } catch (e) {
      AppLogger.i('Error removing FCM token: $e');
    }
  }

  static Future<void> _invokeSendNotification({
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
      await _invokeSendNotification(
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
      await _invokeSendNotification(
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
      await _invokeSendNotification(
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
      await _invokeSendNotification(
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

  static Future<void> sendInvitationNotification({
    required String homeId,
    required String actorId,
    required String invitationId,
    required Map<String, dynamic> context,
    String eventType = 'invitation_received',
    List<String>? targetUserIds,
  }) async {
    try {
      await _invokeSendNotification(
        debugEventName: eventType,
        body: {
          'event_type': eventType,
          'home_id': homeId,
          'actor_id': actorId,
          'reference_id': invitationId,
          'reference_type': 'invitation',
          'context': context,
          if (targetUserIds != null && targetUserIds.isNotEmpty)
            'target_user_ids': targetUserIds,
        },
      );
    } catch (e) {
      AppLogger.i('Error sending invitation notification: $e');
    }
  }

  static Future<void> sendMemberJoinedNotification({
    required String homeId,
    required String actorId,
    required Map<String, dynamic> context,
  }) async {
    try {
      await _invokeSendNotification(
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

class _NotificationGroupInfo {
  final String groupKey;
  final String category;
  final String homeId;

  const _NotificationGroupInfo({
    required this.groupKey,
    required this.category,
    required this.homeId,
  });
}
