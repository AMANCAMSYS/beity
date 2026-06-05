import 'package:flutter/foundation.dart';

class ActionDebouncer {
  static final Set<String> _processingKeys = <String>{};

  /// Executes [action] only if the same call site is not already processing.
  ///
  /// This keeps legacy `ActionDebouncer.execute(...)` call sites from blocking
  /// unrelated buttons elsewhere in the app while still preventing rapid
  /// repeated taps on the same action.
  static Future<void> execute(AsyncCallback action, {String? key}) async {
    final actionKey = key ?? action.hashCode.toString();
    if (_processingKeys.contains(actionKey)) return;
    _processingKeys.add(actionKey);
    try {
      await action();
    } finally {
      // Small delay to ensure the UI updates/navigates before re-enabling
      await Future.delayed(const Duration(milliseconds: 300));
      _processingKeys.remove(actionKey);
    }
  }
}
