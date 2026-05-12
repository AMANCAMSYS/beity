import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  static Future<void> initialize() async {
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
      _fcmToken = await _messaging.getToken();

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
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': _getPlatform(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');
    } catch (e) {
      // Silently handle token save errors
    }
  }

  static String _getPlatform() {
    // This is a simplified version - in production, use platform detection
    return 'flutter';
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification or update UI
    // This will be implemented with flutter_local_notifications
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
  }

  static Future<void> sendInvitationNotification({
    required String inviteeEmail,
    required String homeName,
    required String inviterName,
  }) async {
    // This would typically call a Supabase Edge Function to send the notification
    // For now, we'll just log it
  }

  static Future<void> sendInvitationAcceptedNotification({
    required String homeId,
    required String inviterId,
    required String inviteeName,
  }) async {
    // This would typically call a Supabase Edge Function to send the notification
  }

  static Future<void> sendRoleChangedNotification({
    required String userId,
    required String homeId,
    required String newRole,
  }) async {
    // This would typically call a Supabase Edge Function to send the notification
  }
}
