import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    super.homeId,
    required super.name,
    required super.type,
    super.icon,
    super.color,
    super.sortOrder = 0,
    super.isDefault = false,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String?,
      name: json['name'] as String,
      type: _parseType(json['type'] as String),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
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
      'type': type.name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'is_default': isDefault,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  static CategoryType _parseType(String type) {
    switch (type) {
      case 'shopping':
        return CategoryType.shopping;
      case 'inventory':
        return CategoryType.inventory;
      case 'expense':
        return CategoryType.expense;
      default:
        return CategoryType.shopping;
    }
  }

  CategoryModel copyWithModel({
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
    return CategoryModel(
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
