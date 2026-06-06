import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../supabase_service.dart';
import '../app_logger.dart';
import '../../../app/config/env_config.dart';

class NotificationTokenManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

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
        await saveTokenToSupabase(_fcmToken!);
      }
    } catch (e) {
      AppLogger.i('Error refreshing FCM token: $e');
    }
  }

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

  static Future<void> saveTokenToSupabase(String token) async {
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
        'platform': getPlatform(),
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

  static String getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'web';
  }
}
