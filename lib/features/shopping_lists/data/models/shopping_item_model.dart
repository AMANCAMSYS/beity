import '../../domain/entities/shopping_item.dart';

const _modelSentinel = Object();

class ShoppingItemModel extends ShoppingItem {
  const ShoppingItemModel({
    required super.id,
    required super.shoppingListId,
    required super.name,
    super.quantity = 1,
    super.purchasedQuantity = 0,
    super.unitId,
    super.categoryId,
    super.priority = 'medium',
    super.price,
    super.currency,
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
    final id = json['id'] as String?;
    final listId = json['list_id'] as String?;
    final name = json['name'] as String?;

    // Defensive: if critical fields are missing, this is a corrupt payload.
    // Return a minimal model instead of crashing the entire sync pipeline.
    if (id == null || listId == null || name == null) {
      return ShoppingItemModel(
        id: id ?? 'unknown',
        shoppingListId: listId ?? 'unknown',
        name: name ?? 'unknown',
        createdBy: json['created_by'] as String? ?? 'unknown',
      );
    }

    return ShoppingItemModel(
      id: id,
      shoppingListId: listId,
      name: name,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      purchasedQuantity: (json['purchased_quantity'] as num?)?.toDouble() ?? 0,
      unitId: json['unit_id'] as String?,
      categoryId: json['category_id'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      price: (json['estimated_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'SAR',
      notes: json['note'] as String?,
      isPurchased: status == 'completed',
      purchasedBy: json['completed_by'] as String?,
      purchasedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdBy: json['created_by'] as String? ?? 'unknown',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': shoppingListId,
      'name': name,
      'quantity': quantity,
      'purchased_quantity': purchasedQuantity,
      'unit_id': unitId,
      'category_id': categoryId,
      'priority': priority,
      'estimated_price': price,
      'currency': currency,
      'note': notes,
      'status': isPurchased ? 'completed' : 'pending',
      'completed_by': purchasedBy,
      'completed_at': purchasedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'list_id': shoppingListId,
      'name': name,
      'quantity': quantity,
      'purchased_quantity': purchasedQuantity,
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
    double? purchasedQuantity,
    Object? unitId = _modelSentinel,
    Object? categoryId = _modelSentinel,
    String? priority,
    Object? price = _modelSentinel,
    Object? currency = _modelSentinel,
    Object? notes = _modelSentinel,
    bool? isPurchased,
    Object? purchasedBy = _modelSentinel,
    Object? purchasedAt = _modelSentinel,
    String? createdBy,
    Object? createdAt = _modelSentinel,
    Object? updatedAt = _modelSentinel,
    Object? deletedAt = _modelSentinel,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      purchasedQuantity: purchasedQuantity ?? this.purchasedQuantity,
      unitId: identical(unitId, _modelSentinel)
          ? this.unitId
          : unitId as String?,
      categoryId: identical(categoryId, _modelSentinel)
          ? this.categoryId
          : categoryId as String?,
      priority: priority ?? this.priority,
      price: identical(price, _modelSentinel) ? this.price : price as double?,
      currency: identical(currency, _modelSentinel)
          ? this.currency
          : currency as String?,
      notes: identical(notes, _modelSentinel) ? this.notes : notes as String?,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedBy: identical(purchasedBy, _modelSentinel)
          ? this.purchasedBy
          : purchasedBy as String?,
      purchasedAt: identical(purchasedAt, _modelSentinel)
          ? this.purchasedAt
          : purchasedAt as DateTime?,
      createdBy: createdBy ?? this.createdBy,
      createdAt: identical(createdAt, _modelSentinel)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _modelSentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      deletedAt: identical(deletedAt, _modelSentinel)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }
}
