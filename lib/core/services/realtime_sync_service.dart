import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'realtime/realtime_channel_manager.dart';
import 'realtime/realtime_event_handler.dart';
import 'realtime/realtime_table_handlers.dart';
import 'realtime/realtime_debounce.dart';

class RealtimeSyncService {
  final RealtimeChannelManager _channelManager;
  final RealtimeEventHandler _eventHandler;
  final RealtimeTableHandlers _tableHandlers;
  final RealtimeDebouncer _debouncer;

  RealtimeSyncService(SupabaseClient client, Ref ref)
    : this.withDebouncer(client, ref, RealtimeDebouncer());

  RealtimeSyncService.withDebouncer(
    SupabaseClient client,
    Ref ref,
    RealtimeDebouncer debouncer,
  ) : _debouncer = debouncer,
      _channelManager = RealtimeChannelManager(client),
      _eventHandler = RealtimeEventHandler(),
      _tableHandlers = RealtimeTableHandlers(client, ref, debouncer);

  bool get isBuffering => _eventHandler.isBuffering;
  int get bufferedEventCount => _eventHandler.bufferedEventCount;
  int get debounceTimerCount => _debouncer.timerCount;

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final homeId = _channelManager.currentHomeId;
    if (homeId == null || homeId.isEmpty) return;

    _eventHandler.reset();
    _channelManager.unsubscribe();
    _initChannel(homeId);
  }

  void initBuffered(String homeId) {
    if (homeId.isEmpty) return;
    if (_channelManager.currentHomeId == homeId && _eventHandler.isBuffering) {
      return;
    }
    _eventHandler.clearBuffer();
    _initChannel(homeId);
    _eventHandler.startBuffering();
  }

  Future<void> flushBuffer() async {
    _debouncer.isFlushingBuffer = true;
    try {
      await _eventHandler.flushBuffer(
        _channelManager.currentHomeId ?? '',
        (event) => _applyRealtimeEvent(event),
      );
    } finally {
      _debouncer.isFlushingBuffer = false;
    }
  }

  void init(String homeId) {
    _eventHandler.reset();
    _initChannel(homeId);
  }

  void _initChannel(String homeId) {
    _tableHandlers.currentHomeId = homeId;
    _channelManager.subscribeToHome(
      homeId,
      (table, payload) => _receiveRealtimeEvent(table, payload),
    );
  }

  void unsubscribe() {
    _debouncer.cancelAll();
    _channelManager.unsubscribe();
    _eventHandler.reset();
  }

  void _receiveRealtimeEvent(String table, PostgresChangePayload payload) {
    final homeId = _channelManager.currentHomeId;
    if (homeId == null) return;

    _eventHandler.receiveEvent(
      table,
      homeId,
      payload,
      (event) => _applyRealtimeEvent(event),
    );
  }

  Future<void> _applyRealtimeEvent(RealtimeEvent event) async {
    switch (event.table) {
      case 'shopping_lists':
        return _tableHandlers.handleShoppingListEvent(event.payload);
      case 'shopping_items':
        return _tableHandlers.handleShoppingItemEvent(event.payload);
      case 'tasks':
        return _tableHandlers.handleTaskEvent(event.payload);
      case 'expenses':
        return _tableHandlers.handleExpenseEvent(event.payload);
      case 'inventory_items':
        return _tableHandlers.handleInventoryItemEvent(event.payload);
      case 'categories':
        return _tableHandlers.handleCategoryEvent(event.payload);
      case 'home_members':
        return _tableHandlers.handleHomeMemberEvent(event.payload);
      case 'notifications':
        return _tableHandlers.handleNotificationEvent(event.payload);
    }
  }
}

/// Provider for [RealtimeSyncService]
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService(SupabaseService.client, ref);
  ref.onDispose(() => service.unsubscribe());
  return service;
});
