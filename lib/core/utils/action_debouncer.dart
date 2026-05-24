import 'package:flutter/foundation.dart';

class ActionDebouncer {
  static bool _isProcessing = false;

  /// Executes [action] only if no other action is currently processing.
  /// Ideal for preventing double-taps on buttons.
  static void execute(AsyncCallback action) async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      await action();
    } finally {
      // Small delay to ensure the UI updates/navigates before re-enabling
      await Future.delayed(const Duration(milliseconds: 300));
      _isProcessing = false;
    }
  }
}
