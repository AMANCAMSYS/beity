enum ShoppingListStatus {
  active,
  completed,
  archived,
  cancelled;

  String get translationKey {
    switch (this) {
      case ShoppingListStatus.active:
        return 'status_active';
      case ShoppingListStatus.completed:
        return 'status_completed';
      case ShoppingListStatus.archived:
        return 'status_archived';
      case ShoppingListStatus.cancelled:
        return 'status_cancelled';
    }
  }
}

const _sentinel = Object();

class ShoppingList {
  final String id;
  final String homeId;
  final String name;
  final String? description;
  final String icon;
  final String createdBy;
  final ShoppingListStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? inventoryTransferredAt;
  final int itemCount;
  final int purchasedCount;

  const ShoppingList({
    required this.id,
    required this.homeId,
    required this.name,
    this.description,
    this.icon = 'shopping_cart',
    required this.createdBy,
    this.status = ShoppingListStatus.active,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.inventoryTransferredAt,
    this.itemCount = 0,
    this.purchasedCount = 0,
  });

  bool get isArchived => status == ShoppingListStatus.archived;
  bool get isActive => status == ShoppingListStatus.active;
  bool get isVisibleOnHome => status == ShoppingListStatus.active;
  bool get canTransferToInventory => status == ShoppingListStatus.completed && inventoryTransferredAt == null;

  ShoppingList copyWith({
    String? id,
    String? homeId,
    String? name,
    Object? description = _sentinel,
    String? icon,
    String? createdBy,
    ShoppingListStatus? status,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? deletedAt = _sentinel,
    Object? inventoryTransferredAt = _sentinel,
    int? itemCount,
    int? purchasedCount,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      icon: icon ?? this.icon,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: identical(createdAt, _sentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _sentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      deletedAt: identical(deletedAt, _sentinel)
          ? this.deletedAt
          : deletedAt as DateTime?,
      inventoryTransferredAt: identical(inventoryTransferredAt, _sentinel)
          ? this.inventoryTransferredAt
          : inventoryTransferredAt as DateTime?,
      itemCount: itemCount ?? this.itemCount,
      purchasedCount: purchasedCount ?? this.purchasedCount,
    );
  }
}
