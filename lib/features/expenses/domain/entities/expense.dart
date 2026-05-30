class Expense {
  final String id;
  final String homeId;
  final int amount; // cents
  final String description;
  final DateTime date;
  final String? categoryId;
  final String paidBy;
  final String? shoppingListItemId;
  final String currencyCode;
  final int convertedAmount; // cents
  final String status; // 'active' or 'cancelled'
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Expense({
    required this.id,
    required this.homeId,
    required this.amount,
    required this.description,
    required this.date,
    this.categoryId,
    required this.paidBy,
    this.shoppingListItemId,
    this.currencyCode = 'TRY',
    required this.convertedAmount,
    this.status = 'active',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isCancelled => status == 'cancelled';
  bool get isDeleted => deletedAt != null;

  Expense copyWith({
    String? id,
    String? homeId,
    int? amount,
    String? description,
    DateTime? date,
    String? categoryId,
    String? paidBy,
    String? shoppingListItemId,
    String? currencyCode,
    int? convertedAmount,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      paidBy: paidBy ?? this.paidBy,
      shoppingListItemId: shoppingListItemId ?? this.shoppingListItemId,
      currencyCode: currencyCode ?? this.currencyCode,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
