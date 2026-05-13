enum ShoppingListStatus {
  active,
  archived;

  String get displayName {
    switch (this) {
      case ShoppingListStatus.active:
        return 'نشط';
      case ShoppingListStatus.archived:
        return 'مؤرشف';
    }
  }
}

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
  });

  bool get isArchived => status == ShoppingListStatus.archived;
  bool get isActive => status == ShoppingListStatus.active;

  ShoppingList copyWith({
    String? id,
    String? homeId,
    String? name,
    String? description,
    String? icon,
    String? createdBy,
    ShoppingListStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
