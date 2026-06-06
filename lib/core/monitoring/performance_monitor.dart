import 'dart:async';

import 'monitoring_service.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._();

  final MonitoringService _monitoring = MonitoringService();

  /// Wraps an async operation and logs performance if it exceeds the threshold.
  Future<T> measure<T>({
    required String operation,
    required Future<T> Function() action,
    String? screen,
    int? itemCount,
    int thresholdMs = 3000,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await action();
      stopwatch.stop();

      if (stopwatch.elapsedMilliseconds > thresholdMs) {
        await _monitoring.logPerformanceEvent(
          operation: operation,
          durationMs: stopwatch.elapsedMilliseconds,
          screen: screen,
          itemCount: itemCount,
        );
      }

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      await _monitoring.logError(
        e,
        stackTrace,
        reason:
            'Failed operation: $operation (${stopwatch.elapsedMilliseconds}ms)',
      );
      rethrow;
    }
  }
}
