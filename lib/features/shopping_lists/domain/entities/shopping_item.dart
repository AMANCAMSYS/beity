class ShoppingItem {
  final String id;
  final String shoppingListId;
  final String name;
  final double quantity;
  final String? unitId;
  final String? categoryId;
  final double? price;
  final String currency;
  final String? notes;
  final bool isPurchased;
  final String? purchasedBy;
  final DateTime? purchasedAt;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShoppingItem({
    required this.id,
    required this.shoppingListId,
    required this.name,
    this.quantity = 1,
    this.unitId,
    this.categoryId,
    this.price,
    this.currency = 'SAR',
    this.notes,
    this.isPurchased = false,
    this.purchasedBy,
    this.purchasedAt,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasPrice => price != null && price! > 0;
  
  String get formattedPrice {
    if (!hasPrice) return '';
    return '${price!.toStringAsFixed(2)} $currency';
  }

  ShoppingItem copyWith({
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
  }) {
    return ShoppingItem(
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
    );
  }
}
