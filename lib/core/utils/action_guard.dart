import 'dart:async';

/// A utility to prevent multiple simultaneous executions of an action,
/// typically used for buttons to prevent double-taps.
class ActionGuard {
  bool _isRunning = false;
  Timer? _cooldown;

  Future<void> run(Future<void> Function() action) async {
    if (_isRunning) return;
    _isRunning = true;
    try {
      await action();
    } finally {
      _cooldown?.cancel();
      _cooldown = Timer(const Duration(milliseconds: 500), () {
        _isRunning = false;
      });
    }
  }

  void dispose() {
    _cooldown?.cancel();
  }
}
