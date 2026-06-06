enum UnitType { weight, volume, count, length }

class Unit {
  final String id;
  final String name;
  final String symbol;
  final UnitType type;
  final bool isDefault;
  final DateTime? createdAt;

  const Unit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    this.isDefault = false,
    this.createdAt,
  });

  Unit copyWith({
    String? id,
    String? name,
    String? symbol,
    UnitType? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
