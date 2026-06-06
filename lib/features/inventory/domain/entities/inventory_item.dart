class InventoryItem {
  final String id;
  final String homeId;
  final String name;
  final double quantity;
  final String? unitId;
  final String? categoryId;
  final double? minQuantity;
  final String? notes;
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const InventoryItem({
    required this.id,
    required this.homeId,
    required this.name,
    this.quantity = 0,
    this.unitId,
    this.categoryId,
    this.minQuantity,
    this.notes,
    required this.createdBy,
    required this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isLowStock => minQuantity != null && quantity <= minQuantity!;

  double get restockSuggestion =>
      minQuantity != null ? (minQuantity! * 2) - quantity : 0;

  InventoryItem copyWith({
    String? id,
    String? homeId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? minQuantity,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      categoryId: categoryId ?? this.categoryId,
      minQuantity: minQuantity ?? this.minQuantity,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
