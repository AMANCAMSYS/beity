class ShoppingModeSession {
  final String id;
  final String shoppingListId;
  final String userId;
  final String homeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int itemsPurchasedCount;
  final int itemsTotalCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShoppingModeSession({
    required this.id,
    required this.shoppingListId,
    required this.userId,
    required this.homeId,
    required this.startedAt,
    this.endedAt,
    this.itemsPurchasedCount = 0,
    this.itemsTotalCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => endedAt == null;
  bool get isComplete =>
      itemsPurchasedCount == itemsTotalCount && itemsTotalCount > 0;
  double get progress =>
      itemsTotalCount > 0 ? itemsPurchasedCount / itemsTotalCount : 0;

  ShoppingModeSession copyWith({
    String? id,
    String? shoppingListId,
    String? userId,
    String? homeId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? itemsPurchasedCount,
    int? itemsTotalCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingModeSession(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      userId: userId ?? this.userId,
      homeId: homeId ?? this.homeId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      itemsPurchasedCount: itemsPurchasedCount ?? this.itemsPurchasedCount,
      itemsTotalCount: itemsTotalCount ?? this.itemsTotalCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
