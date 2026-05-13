class ItemTemplate {
  final String id;
  final String homeId;
  final String name;
  final double defaultQuantity;
  final String? defaultUnitId;
  final String? defaultCategoryId;
  final int usageCount;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItemTemplate({
    required this.id,
    required this.homeId,
    required this.name,
    this.defaultQuantity = 1,
    this.defaultUnitId,
    this.defaultCategoryId,
    this.usageCount = 0,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  ItemTemplate copyWith({
    String? id,
    String? homeId,
    String? name,
    double? defaultQuantity,
    String? defaultUnitId,
    String? defaultCategoryId,
    int? usageCount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemTemplate(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      defaultUnitId: defaultUnitId ?? this.defaultUnitId,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      usageCount: usageCount ?? this.usageCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
