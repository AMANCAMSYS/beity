import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'app_log_buffer.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._();
  factory MonitoringService() => _instance;
  MonitoringService._();

  FirebaseCrashlytics? _crashlytics;
  final AppLogBuffer _logBuffer = AppLogBuffer();

  // T145-T149: Performance checkpoint timestamps
  DateTime? _appStartTime;
  DateTime? _homeFirstRenderTime;
  DateTime? _shoppingListFirstRenderTime;
  DateTime? _addItemLocalCommitTime;
  DateTime? _syncCompletionTime;

  // T150-T152: Offline queue metrics
  int _pendingOperationCount = 0;
  String? _lastSyncErrorId;
  int _retryCount = 0;

  FirebaseCrashlytics? get _safeCrashlytics {
    try {
      return _crashlytics ??= FirebaseCrashlytics.instance;
    } catch (_) {
      return null;
    }
  }

  // ─── T145-T149: Performance Checkpoint Getters ───

  DateTime? get appStartTime => _appStartTime;
  DateTime? get homeFirstRenderTime => _homeFirstRenderTime;
  DateTime? get shoppingListFirstRenderTime => _shoppingListFirstRenderTime;
  DateTime? get addItemLocalCommitTime => _addItemLocalCommitTime;
  DateTime? get syncCompletionTime => _syncCompletionTime;

  // ─── T150-T152: Offline Queue Metric Getters ───

  int get pendingOperationCount => _pendingOperationCount;
  String? get lastSyncErrorId => _lastSyncErrorId;
  int get retryCount => _retryCount;

  Future<void> initialize() async {
    if (kIsWeb) return;

    final crashlytics = _safeCrashlytics;
    if (crashlytics == null) return;

    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = (FlutterErrorDetails details) {
      crashlytics.recordFlutterError(details);
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
  }

  Future<void> setUser(String userId) async {
    if (kIsWeb) return;
    await _safeCrashlytics?.setUserIdentifier(userId);
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (kIsWeb) return;
    await _safeCrashlytics?.setCustomKey(key, value.toString());
  }

  Future<void> log(String message) async {
    _logBuffer.add(message);
    if (kIsWeb) return;
    await _safeCrashlytics?.log(message);
  }

  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    _logBuffer.add('ERROR: ${exception.toString()}');
    if (kIsWeb) return;
    await _safeCrashlytics?.recordError(
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

    if (kIsWeb) return;

    final crashlytics = _safeCrashlytics;
    if (crashlytics == null) return;

    if (durationMs > 3000) {
      await crashlytics.recordError(
        Exception('Slow operation: $operation'),
        StackTrace.current,
        reason: message,
      );
    }

    await crashlytics.log(message);
  }

  // ─── T143: Crashlytics Breadcrumbs ───

  Future<void> breadcrumbOnboardingComplete() async {
    await log('BREADCRUMB: onboarding_complete');
    await setCustomKey('last_flow', 'onboarding_complete');
  }

  Future<void> breadcrumbAuthSignIn({String? userId}) async {
    await log('BREADCRUMB: auth_sign_in');
    if (userId != null) {
      await setCustomKey('last_auth_action', 'sign_in');
    }
  }

  Future<void> breadcrumbAuthSignUp({String? userId}) async {
    await log('BREADCRUMB: auth_sign_up');
    if (userId != null) {
      await setCustomKey('last_auth_action', 'sign_up');
    }
  }

  Future<void> breadcrumbAuthSignOut() async {
    await log('BREADCRUMB: auth_sign_out');
    await setCustomKey('last_auth_action', 'sign_out');
  }

  Future<void> breadcrumbHomeSelected(String homeId) async {
    await log('BREADCRUMB: home_selected $homeId');
    await setCustomKey('home_id', homeId);
  }

  Future<void> breadcrumbShoppingListOpen(String listId) async {
    await log('BREADCRUMB: shopping_list_open $listId');
    await setCustomKey('list_id', listId);
  }

  Future<void> breadcrumbAddItem(String listId) async {
    await log('BREADCRUMB: add_item list=$listId');
  }

  Future<void> breadcrumbShoppingModeStart(String listId) async {
    await log('BREADCRUMB: shopping_mode_start list=$listId');
    await setCustomKey('shopping_mode', 'active');
  }

  Future<void> breadcrumbShoppingModeEnd(String listId) async {
    await log('BREADCRUMB: shopping_mode_end list=$listId');
    await setCustomKey('shopping_mode', 'inactive');
  }

  // ─── T144: Safe ID Custom Keys ───

  Future<void> setHomeId(String homeId) async {
    await setCustomKey('home_id', homeId);
  }

  Future<void> setListId(String listId) async {
    await setCustomKey('list_id', listId);
  }

  Future<void> setUserId(String userId) async {
    await setCustomKey('user_id', userId);
  }

  // ─── T145-T149: Performance Checkpoints ───

  void markAppStart() {
    _appStartTime = DateTime.now();
    _logBuffer.add(
      'CHECKPOINT: app_start at ${_appStartTime!.toIso8601String()}',
    );
  }

  void markHomeFirstRender() {
    _homeFirstRenderTime = DateTime.now();
    _logBuffer.add(
      'CHECKPOINT: home_first_render at ${_homeFirstRenderTime!.toIso8601String()}'
      '${_appStartTime != null ? ' (+${_homeFirstRenderTime!.difference(_appStartTime!).inMilliseconds}ms from start)' : ''}',
    );
  }

  void markShoppingListFirstRender() {
    _shoppingListFirstRenderTime = DateTime.now();
    _logBuffer.add(
      'CHECKPOINT: shopping_list_first_render at ${_shoppingListFirstRenderTime!.toIso8601String()}'
      '${_appStartTime != null ? ' (+${_shoppingListFirstRenderTime!.difference(_appStartTime!).inMilliseconds}ms from start)' : ''}',
    );
  }

  void markAddItemLocalCommit() {
    _addItemLocalCommitTime = DateTime.now();
    _logBuffer.add(
      'CHECKPOINT: add_item_local_commit at ${_addItemLocalCommitTime!.toIso8601String()}',
    );
  }

  void markSyncCompletion() {
    _syncCompletionTime = DateTime.now();
    _logBuffer.add(
      'CHECKPOINT: sync_completion at ${_syncCompletionTime!.toIso8601String()}'
      '${_appStartTime != null ? ' (+${_syncCompletionTime!.difference(_appStartTime!).inMilliseconds}ms from start)' : ''}',
    );
  }

  // ─── T150-T152: Offline Queue Metrics ───

  void updatePendingOperationCount(int count) {
    _pendingOperationCount = count;
    _logBuffer.add('METRIC: pending_operations=$count');
  }

  void updateLastSyncErrorId(String? errorId) {
    _lastSyncErrorId = errorId;
    _logBuffer.add('METRIC: last_sync_error=${errorId ?? "none"}');
  }

  void incrementRetryCount() {
    _retryCount++;
    _logBuffer.add('METRIC: retry_count=$_retryCount');
  }

  void resetRetryCount() {
    _retryCount = 0;
  }

  List<String> getRecentLogs() => _logBuffer.getRecent();
}
