const _sentinel = Object();

class ShoppingItem {
  final String id;
  final String shoppingListId;
  final String name;
  final double quantity;
  final double purchasedQuantity;
  final String? unitId;
  final String? categoryId;
  final String priority;
  final double? price;
  final String? currency;
  final String? notes;
  final bool isPurchased;
  final String? purchasedBy;
  final DateTime? purchasedAt;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ShoppingItem({
    required this.id,
    required this.shoppingListId,
    required this.name,
    this.quantity = 1,
    this.purchasedQuantity = 0,
    this.unitId,
    this.categoryId,
    this.priority = 'medium',
    this.price,
    this.currency,
    this.notes,
    this.isPurchased = false,
    this.purchasedBy,
    this.purchasedAt,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get hasPrice => price != null && price! > 0;

  String get formattedPrice {
    if (!hasPrice) return '';
    return '${price!.toStringAsFixed(2)} ${currency ?? ''}';
  }

  /// Priority order value for sorting (lower = higher priority).
  static int priorityOrder(String priority) {
    switch (priority) {
      case 'urgent': return 0;
      case 'high': return 1;
      case 'medium': return 2;
      case 'low': return 3;
      default: return 2;
    }
  }

  ShoppingItem copyWith({
    String? id,
    String? shoppingListId,
    String? name,
    double? quantity,
    double? purchasedQuantity,
    Object? unitId = _sentinel,
    Object? categoryId = _sentinel,
    String? priority,
    Object? price = _sentinel,
    Object? currency = _sentinel,
    Object? notes = _sentinel,
    bool? isPurchased,
    Object? purchasedBy = _sentinel,
    Object? purchasedAt = _sentinel,
    String? createdBy,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? deletedAt = _sentinel,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      purchasedQuantity: purchasedQuantity ?? this.purchasedQuantity,
      unitId: identical(unitId, _sentinel) ? this.unitId : unitId as String?,
      categoryId: identical(categoryId, _sentinel) ? this.categoryId : categoryId as String?,
      priority: priority ?? this.priority,
      price: identical(price, _sentinel) ? this.price : price as double?,
      currency: identical(currency, _sentinel) ? this.currency : currency as String?,
      notes: identical(notes, _sentinel) ? this.notes : notes as String?,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedBy: identical(purchasedBy, _sentinel) ? this.purchasedBy : purchasedBy as String?,
      purchasedAt: identical(purchasedAt, _sentinel) ? this.purchasedAt : purchasedAt as DateTime?,
      createdBy: createdBy ?? this.createdBy,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _sentinel) ? this.updatedAt : updatedAt as DateTime?,
      deletedAt: identical(deletedAt, _sentinel) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
