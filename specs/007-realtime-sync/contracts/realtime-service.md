# Contract: RealtimeService Interface

**Date**: 2026-05-13
**Feature**: 007-realtime-sync

This contract defines the interface for the shared RealtimeService that all features use for Supabase Realtime subscriptions.

## RealtimeService (Dart Interface)

```dart
abstract class RealtimeService {
  /// Subscribe to Postgres Changes on a table filtered by a column value.
  /// Returns a Stream of row changes (INSERT, UPDATE, DELETE).
  /// Channel is automatically managed (subscribe on first listen, unsubscribe on last).
  Stream<List<Map<String, dynamic>>> watchTable({
    required String table,
    required String filterColumn,
    required String filterValue,
    required List<String> primaryKey,
  });

  /// Subscribe to presence on a scoped channel.
  /// Returns a Stream of current presence state (Map of userId → PresenceState).
  Stream<Map<String, PresenceState>> watchPresence({
    required String channelName,
    required PresencePayload userPayload,
  });

  /// Track connection state changes.
  /// Returns a Stream of ConnectionStatus transitions.
  Stream<ConnectionState> get connectionState;

  /// Fetch missed changes since a given timestamp for a table.
  /// Used on reconnection to sync gaps.
  Future<List<Map<String, dynamic>>> fetchMissedChanges({
    required String table,
    required String filterColumn,
    required String filterValue,
    required DateTime since,
    required String orderBy,
  });

  /// Clean up all subscriptions. Called on logout.
  Future<void> disposeAll();
}
```

## PresencePayload (Input)

```dart
class PresencePayload {
  final String userId;
  final String displayName;
  final String? avatarUrl;
}
```

## PresenceState (Output)

```dart
class PresenceState {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime joinedAt;
}
```

## ConnectionState (Output)

```dart
enum ConnectionStatus { connected, disconnected, reconnecting }

class ConnectionState {
  final ConnectionStatus status;
  final DateTime? lastConnectedAt;
}
```

## OfflineQueueEntry (Data)

```dart
enum QueueOperation { add, update, delete, markPurchased }

class OfflineQueueEntry {
  final String id;
  final QueueOperation operation;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
}
```

## Error Handling Contract

| Scenario | Behavior |
|----------|----------|
| Channel subscribe fails | Retry with exponential backoff (1s, 2s, 4s, max 30s). After 3 retries, show error state in UI. |
| Presence join fails | Log warning, continue without presence. Non-blocking. |
| Network drops mid-subscription | Auto-reconnect handled by Supabase SDK. Emit `ConnectionState.disconnected` then `reconnecting` then `connected`. |
| Fetch missed changes fails | Retry once. If still fails, show error snackbar with "Tap to retry". |
| User removed from home | Receive DELETE event on home_members stream → show dialog → redirect to homes list. |
