import '../../domain/entities/shopping_list.dart';

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
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      name: json['title'] as String,
      description: json['type'] as String?,
      icon: json['icon'] as String? ?? 'shopping_cart',
      createdBy: json['created_by'] as String,
      status: _parseStatus(json['status'] as String? ?? 'active'),
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
      'title': name,
      'type': description ?? 'grocery',
      'icon': icon,
      'status': status.name,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'home_id': homeId,
      'title': name,
      'type': description ?? 'grocery',
      'icon': icon,
      'created_by': createdBy,
    };
  }

  static ShoppingListStatus _parseStatus(String status) {
    switch (status) {
      case 'active':
        return ShoppingListStatus.active;
      case 'archived':
        return ShoppingListStatus.archived;
      case 'completed':
        return ShoppingListStatus.archived;
      default:
        return ShoppingListStatus.active;
    }
  }

  ShoppingListModel copyWithModel({
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
    return ShoppingListModel(
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
