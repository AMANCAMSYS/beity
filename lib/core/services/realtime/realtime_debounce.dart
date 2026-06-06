import 'dart:async';
import '../app_logger.dart';

class RealtimeDebouncer {
  final Map<String, Timer> _debounceTimers = {};
  bool isFlushingBuffer = false;
  int get timerCount => _debounceTimers.length;

  Future<void> debounceSync(
    String domain,
    Future<void> Function() action,
  ) async {
    _debounceTimers[domain]?.cancel();
    if (isFlushingBuffer) {
      _debounceTimers.remove(domain);
      await action();
      return;
    }

    _debounceTimers[domain] = Timer(
      const Duration(milliseconds: 800),
      () async {
        try {
          await action();
        } catch (e) {
          AppLogger.i('[RealtimeSync] Debounce error ($domain): $e');
        }
      },
    );
  }

  void cancelAll() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}
