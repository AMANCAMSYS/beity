import '../../domain/entities/inventory_item.dart';

class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required super.id,
    required super.homeId,
    required super.name,
    super.quantity = 0,
    super.unitId,
    super.categoryId,
    super.minQuantity,
    super.notes,
    required super.createdBy,
    required super.updatedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String? ?? '',
      homeId: json['home_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitId: json['unit_id'] as String?,
      categoryId: json['category_id'] as String?,
      minQuantity: (json['min_quantity'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      updatedBy: json['updated_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'name': name,
      'quantity': quantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'min_quantity': minQuantity,
      'notes': notes,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'home_id': homeId,
      'name': name,
      'quantity': quantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'min_quantity': minQuantity,
      'notes': notes,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  InventoryItemModel copyWithModel({
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
    return InventoryItemModel(
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
