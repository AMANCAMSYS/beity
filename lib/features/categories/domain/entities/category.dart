enum CategoryType {
  shopping,
  inventory,
  expense;
}

class Category {
  final String id;
  final String? homeId;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool isDefault;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    this.homeId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.isDefault = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isCustom => !isDefault && homeId != null;

  Category copyWith({
    String? id,
    String? homeId,
    String? name,
    CategoryType? type,
    String? icon,
    String? color,
    int? sortOrder,
    bool? isDefault,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Category(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
