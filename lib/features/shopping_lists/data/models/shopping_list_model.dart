import '../../domain/entities/shopping_list.dart';

const _modelSentinel = Object();

class ShoppingListModel extends ShoppingList {
  const ShoppingListModel({
    required super.id,
    required super.homeId,
    required super.name,
    super.description,
    super.icon,
    required super.createdBy,
    super.status = ShoppingListStatus.active,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.inventoryTransferredAt,
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'] as String? ?? 'unknown',
      homeId: json['home_id'] as String? ?? '',
      name: json['title'] as String? ?? 'Untitled',
      description: json['type'] as String?,
      icon: json['icon'] as String? ?? 'shopping_cart',
      createdBy: json['created_by'] as String? ?? 'unknown',
      status: _parseStatus(json['status'] as String? ?? 'active'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
      inventoryTransferredAt: json['inventory_transferred_at'] != null
          ? DateTime.tryParse(json['inventory_transferred_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'title': name,
      'type': description ?? 'grocery',
      'icon': icon,
      'status': status.name,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'inventory_transferred_at': inventoryTransferredAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'home_id': homeId,
      'title': name,
      'type': 'grocery',
      'icon': icon,
      'created_by': createdBy,
    };
  }

  static ShoppingListStatus _parseStatus(String status) {
    switch (status) {
      case 'active':
        return ShoppingListStatus.active;
      case 'completed':
        return ShoppingListStatus.completed;
      case 'archived':
        return ShoppingListStatus.archived;
      case 'cancelled':
        return ShoppingListStatus.cancelled;
      default:
        return ShoppingListStatus.active;
    }
  }

  ShoppingListModel copyWithModel({
    String? id,
    String? homeId,
    String? name,
    Object? description = _modelSentinel,
    String? icon,
    String? createdBy,
    ShoppingListStatus? status,
    Object? createdAt = _modelSentinel,
    Object? updatedAt = _modelSentinel,
    Object? deletedAt = _modelSentinel,
    Object? inventoryTransferredAt = _modelSentinel,
  }) {
    return ShoppingListModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      description: identical(description, _modelSentinel) ? this.description : description as String?,
      icon: icon ?? this.icon,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: identical(createdAt, _modelSentinel) ? this.createdAt : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _modelSentinel) ? this.updatedAt : updatedAt as DateTime?,
      deletedAt: identical(deletedAt, _modelSentinel) ? this.deletedAt : deletedAt as DateTime?,
      inventoryTransferredAt: identical(inventoryTransferredAt, _modelSentinel) ? this.inventoryTransferredAt : inventoryTransferredAt as DateTime?,
    );
  }
}
