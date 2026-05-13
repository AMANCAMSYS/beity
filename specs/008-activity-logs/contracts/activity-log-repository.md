# Contract: ActivityLogRepository Interface

**Date**: 2026-05-13
**Feature**: 008-activity-logs

This contract defines the interface for the ActivityLogRepository that the presentation layer uses to read activity logs.

## ActivityLogRepository (Dart Interface)

```dart
abstract class ActivityLogRepository {
  /// Watch activity logs for a home, ordered by newest first.
  /// Returns a Stream that emits on new inserts (via Supabase Realtime).
  /// [limit] defaults to 50, [offset] for pagination.
  Stream<List<ActivityLog>> watchHomeActivity({
    required String homeId,
    int limit = 50,
    int offset = 0,
  });

  /// Watch activity logs for a specific shopping list.
  /// Includes both list-level actions and item-level actions for that list.
  /// Filters by entity_type='shopping_list' AND entity_id=listId
  /// OR metadata->>'list_id' = listId.
  Stream<List<ActivityLog>> watchListActivity({
    required String homeId,
    required String listId,
    int limit = 50,
    int offset = 0,
  });

  /// Fetch activity logs with filters applied.
  /// [actorId] — filter by user_id
  /// [actionTypes] — filter by action values
  Future<List<ActivityLog>> getActivityLogs({
    required String homeId,
    String? actorId,
    List<ActionType>? actionTypes,
    int limit = 50,
    int offset = 0,
  });

  /// Get distinct actors who have entries in a home's activity log.
  /// Used to populate the actor filter dropdown.
  Future<List<ActivityActor>> getHomeActors({required String homeId});
}
```

## ActivityActor (Output)

```dart
class ActivityActor {
  final String userId;
  final String? displayName;
}
```

## Error Handling Contract

| Scenario | Behavior |
|----------|----------|
| Realtime subscription fails | Retry with exponential backoff (1s, 2s, 4s). After 3 retries, fall back to pull-to-refresh. |
| Query fails | Show error state with "Tap to retry" button. |
| Empty result set | Show empty state: "Activity will appear as members interact with shared resources." |
| Network offline | Show cached data if available; otherwise show empty state with offline indicator. |

## Supabase Query Contracts

### Home Activity Feed

```dart
supabase
  .from('activity_logs')
  .select()
  .eq('home_id', homeId)
  .order('created_at', ascending: false)
  .range(offset, offset + limit - 1)
```

### List Activity Feed

```dart
supabase
  .from('activity_logs')
  .select()
  .eq('home_id', homeId)
  .or('and(entity_type.eq.shopping_list,entity_id.eq.$listId),metadata->>list_id.eq.$listId')
  .order('created_at', ascending: false)
  .range(offset, offset + limit - 1)
```

### Filtered Activity

```dart
var query = supabase
  .from('activity_logs')
  .select()
  .eq('home_id', homeId);

if (actorId != null) query = query.eq('user_id', actorId);
if (actionTypes != null && actionTypes.isNotEmpty) {
  query = query.inFilter('action', actionTypes.map((a) => a.value).toList());
}

query.order('created_at', ascending: false).range(offset, offset + limit - 1)
```
