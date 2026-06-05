import 'dart:async';

/// Represents a change event in the local persistent cache.
class LocalCacheEvent {
  final String homeId;
  final String entityType;
  final String? listId;

  /// Purchase-specific metadata for overlay notifications.
  final String? itemName;
  final String? purchaserId;
  final bool? isPurchased;

  LocalCacheEvent({
    required this.homeId,
    required this.entityType,
    this.listId,
    this.itemName,
    this.purchaserId,
    this.isPurchased,
  });

  /// Whether this event represents a purchase state change from another user.
  bool get isPurchaseEvent => itemName != null && isPurchased != null;
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
  ///
  /// [listId] narrows shopping item updates to one list. A null [listId] means
  /// the whole entity type changed for the home and listeners may refresh all
  /// matching scopes.
  static void notify(String homeId, String entityType, {String? listId}) {
    if (!_controller.isClosed) {
      _controller.add(
        LocalCacheEvent(homeId: homeId, entityType: entityType, listId: listId),
      );
    }
  }

  /// Broadcasts a purchase state change event with item metadata.
  ///
  /// Used by the UI to show "أحمد اشترى تفاح ✅" overlay notifications
  /// when another user purchases or un-purchases an item.
  static void notifyPurchase(
    String homeId, {
    required String listId,
    required String itemName,
    String? purchaserId,
    required bool isPurchased,
  }) {
    if (!_controller.isClosed) {
      _controller.add(
        LocalCacheEvent(
          homeId: homeId,
          entityType: 'shopping_items',
          listId: listId,
          itemName: itemName,
          purchaserId: purchaserId,
          isPurchased: isPurchased,
        ),
      );
    }
  }
}
