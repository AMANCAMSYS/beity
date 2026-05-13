import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'app_log_buffer.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._();
  factory MonitoringService() => _instance;
  MonitoringService._();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final AppLogBuffer _logBuffer = AppLogBuffer();

  Future<void> initialize() async {
    // Disable collection in debug builds
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      _crashlytics.recordFlutterError(details);
      // Also print in debug for local debugging
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
  }

  Future<void> setUser(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value.toString());
  }

  Future<void> log(String message) async {
    _logBuffer.add(message);
    await _crashlytics.log(message);
  }

  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    _logBuffer.add('ERROR: ${exception.toString()}');
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  Future<void> logPerformanceEvent({
    required String operation,
    required int durationMs,
    String? screen,
    int? itemCount,
  }) async {
    final message =
        'PERF: $operation took ${durationMs}ms'
        '${screen != null ? ' on $screen' : ''}'
        '${itemCount != null ? ' ($itemCount items)' : ''}';

    _logBuffer.add(message);

    // Log as non-fatal error if > 3 seconds (per FR-014)
    if (durationMs > 3000) {
      await _crashlytics.recordError(
        Exception('Slow operation: $operation'),
        StackTrace.current,
        reason: message,
      );
    }

    await _crashlytics.log(message);
  }

  List<String> getRecentLogs() => _logBuffer.getRecent();
}
