import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_logger.dart';

class RealtimeEvent {
  final String homeId;
  final String table;
  final PostgresChangePayload payload;

  const RealtimeEvent({
    required this.homeId,
    required this.table,
    required this.payload,
  });
}

class RealtimeEventHandler {
  final List<RealtimeEvent> _buffer = <RealtimeEvent>[];
  bool _isBuffering = false;

  bool get isBuffering => _isBuffering;
  int get bufferedEventCount => _buffer.length;

  void startBuffering() {
    _isBuffering = true;
  }

  void stopBuffering() {
    _isBuffering = false;
  }

  void clearBuffer() {
    _buffer.clear();
  }

  void reset() {
    _isBuffering = false;
    _buffer.clear();
  }

  void receiveEvent(
    String table,
    String homeId,
    PostgresChangePayload payload,
    Future<void> Function(RealtimeEvent event) applyEvent,
  ) {
    final event = RealtimeEvent(homeId: homeId, table: table, payload: payload);
    if (_isBuffering) {
      _buffer.add(event);
      return;
    }

    applyEvent(event).catchError((e) {
      AppLogger.i('[RealtimeSync] Error in $table handler: $e');
    });
  }

  Future<void> flushBuffer(
    String currentHomeId,
    Future<void> Function(RealtimeEvent event) applyEvent,
  ) async {
    final pending = List<RealtimeEvent>.from(_buffer);
    _buffer.clear();
    _isBuffering = false;
    try {
      for (final event in pending) {
        if (event.homeId != currentHomeId) continue;
        await applyEvent(event);
      }
    } finally {
      // no-op
    }
  }
}
