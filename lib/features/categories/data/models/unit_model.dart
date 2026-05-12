import '../../domain/entities/unit.dart';

class UnitModel extends Unit {
  const UnitModel({
    required super.id,
    required super.name,
    required super.symbol,
    required super.type,
    super.isDefault = false,
    super.createdAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      type: _parseType(json['type'] as String),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'type': type.name,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static UnitType _parseType(String type) {
    switch (type) {
      case 'weight':
        return UnitType.weight;
      case 'volume':
        return UnitType.volume;
      case 'count':
        return UnitType.count;
      case 'length':
        return UnitType.length;
      default:
        return UnitType.count;
    }
  }

  UnitModel copyWithModel({
    String? id,
    String? name,
    String? symbol,
    UnitType? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return UnitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
