import '../../domain/entities/shopping_item.dart';

class ShoppingItemModel extends ShoppingItem {
  const ShoppingItemModel({
    required super.id,
    required super.shoppingListId,
    required super.name,
    super.quantity = 1,
    super.unitId,
    super.categoryId,
    super.price,
    super.currency = 'SAR',
    super.notes,
    super.isPurchased = false,
    super.purchasedBy,
    super.purchasedAt,
    required super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'pending';
    return ShoppingItemModel(
      id: json['id'] as String,
      shoppingListId: json['list_id'] as String, // Database uses 'list_id'
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitId: json['unit_id'] as String?,
      categoryId: json['category_id'] as String?,
      price: (json['estimated_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'SAR',
      notes: json['note'] as String?, // Database uses 'note' not 'notes'
      isPurchased: status == 'completed', // Database uses 'status' field
      purchasedBy: json['completed_by'] as String?, // Database uses 'completed_by'
      purchasedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
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
      'list_id': shoppingListId,
      'name': name,
      'quantity': quantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'estimated_price': price,
      'currency': currency,
      'note': notes,
      'status': isPurchased ? 'completed' : 'pending',
      'completed_by': purchasedBy,
      'completed_at': purchasedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'list_id': shoppingListId,
      'name': name,
      'quantity': quantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'estimated_price': price,
      'currency': currency,
      'note': notes,
      'created_by': createdBy,
    };
  }

  ShoppingItemModel copyWithModel({
    String? id,
    String? shoppingListId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? price,
    String? currency,
    String? notes,
    bool? isPurchased,
    String? purchasedBy,
    DateTime? purchasedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitId: unitId ?? this.unitId,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
