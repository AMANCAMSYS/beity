import 'dart:async';

/// Represents a change event in the local persistent cache.
class LocalCacheEvent {
  final String homeId;
  final String entityType;

  LocalCacheEvent({
    required this.homeId,
    required this.entityType,
  });
}

/// A global, decoupled reactive broadcaster for local cache updates.
///
/// Used to notify stream-based repository getters when new sync or local modifications
/// are persisted, triggering instant, silent UI updates without network overhead.
class LocalCacheNotifier {
  static final _controller = StreamController<LocalCacheEvent>.broadcast();

  /// Reactive stream of local cache update events.
  static Stream<LocalCacheEvent> get stream => _controller.stream;

  /// Broadcasts a cache update event for a specific [homeId] and [entityType].
  static void notify(String homeId, String entityType) {
    if (!_controller.isClosed) {
      _controller.add(LocalCacheEvent(homeId: homeId, entityType: entityType));
    }
  }
}
