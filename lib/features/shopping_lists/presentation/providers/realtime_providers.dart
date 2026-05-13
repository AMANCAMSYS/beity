import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/realtime_service.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(Supabase.instance.client);
  ref.onDispose(() => service.disposeAll());
  return service;
});

final connectionStateProvider = StreamProvider<ConnectionStateModel>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.connectionState;
});

class OfflineQueueNotifier extends StateNotifier<List<OfflineQueueEntry>> {
  OfflineQueueNotifier() : super(const []);

  int get pendingCount => state.length;

  void enqueue({
    required QueueOperation operation,
    required String entityType,
    String? entityId,
    required Map<String, dynamic> payload,
  }) {
    final entry = OfflineQueueEntry(
      id: const Uuid().v4(),
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
    );
    state = [...state, entry];
  }

  Future<void> flush(Future<void> Function(OfflineQueueEntry) executor) async {
    final entries = List<OfflineQueueEntry>.from(state);
    for (final entry in entries) {
      try {
        await executor(entry);
      } catch (_) {
        continue;
      }
    }
    state = state
        .where((e) => !entries.any((flushed) => flushed.id == e.id))
        .toList();
  }

  void discard() {
    state = const [];
  }
}

final offlineQueueProvider =
    StateNotifierProvider<OfflineQueueNotifier, List<OfflineQueueEntry>>(
  (ref) => OfflineQueueNotifier(),
);

final offlineQueueFlushProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<ConnectionStateModel>>(connectionStateProvider,
      (previous, next) {
    final currentState = next.valueOrNull;
    final previousState = previous?.valueOrNull;
    if (currentState != null &&
        currentState.status == ConnectionStatus.connected &&
        previousState?.status != ConnectionStatus.connected) {
      final queue = ref.read(offlineQueueProvider.notifier);
      if (queue.pendingCount > 0) {
        final client = Supabase.instance.client;
        queue.flush((entry) async {
          switch (entry.operation) {
            case QueueOperation.add:
              await client.from(entry.entityType).insert(entry.payload);
            case QueueOperation.update:
              if (entry.entityId != null) {
                await client
                    .from(entry.entityType)
                    .update(entry.payload)
                    .eq('id', entry.entityId!);
              }
            case QueueOperation.delete:
              if (entry.entityId != null) {
                await client
                    .from(entry.entityType)
                    .update({'deleted_at': DateTime.now().toIso8601String()})
                    .eq('id', entry.entityId!);
              }
            case QueueOperation.markPurchased:
              if (entry.entityId != null) {
                await client
                    .from(entry.entityType)
                    .update(entry.payload)
                    .eq('id', entry.entityId!);
              }
          }
        });
      }
    }
  });
});
