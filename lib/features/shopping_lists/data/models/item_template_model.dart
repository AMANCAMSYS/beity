import '../../domain/entities/item_template.dart';

class ItemTemplateModel extends ItemTemplate {
  const ItemTemplateModel({
    required super.id,
    required super.homeId,
    required super.name,
    super.defaultQuantity = 1,
    super.defaultUnitId,
    super.defaultCategoryId,
    super.usageCount = 0,
    required super.createdBy,
    super.createdAt,
    super.updatedAt,
  });

  factory ItemTemplateModel.fromJson(Map<String, dynamic> json) {
    return ItemTemplateModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      name: json['name'] as String,
      defaultQuantity: (json['default_quantity'] as num?)?.toDouble() ?? 1,
      defaultUnitId: json['default_unit_id'] as String?,
      defaultCategoryId: json['default_category_id'] as String?,
      usageCount: json['usage_count'] as int? ?? 0,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'name': name,
      'default_quantity': defaultQuantity,
      'default_unit_id': defaultUnitId,
      'default_category_id': defaultCategoryId,
      'usage_count': usageCount,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'home_id': homeId,
      'name': name,
      'default_quantity': defaultQuantity,
      'default_unit_id': defaultUnitId,
      'default_category_id': defaultCategoryId,
      'created_by': createdBy,
    };
  }

  ItemTemplateModel copyWithModel({
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
    return ItemTemplateModel(
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
