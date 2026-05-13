import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.homeId,
    required super.amount,
    required super.description,
    required super.date,
    super.categoryId,
    required super.paidBy,
    super.shoppingListItemId,
    super.currencyCode = 'SAR',
    required super.convertedAmount,
    super.status = 'active',
    required super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      amount: json['amount'] as int,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      categoryId: json['category_id'] as String?,
      paidBy: json['paid_by'] as String,
      shoppingListItemId: json['shopping_list_item_id'] as String?,
      currencyCode: json['currency_code'] as String? ?? 'SAR',
      convertedAmount: json['converted_amount'] as int,
      status: json['status'] as String? ?? 'active',
      createdBy: json['created_by'] as String,
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
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'category_id': categoryId,
      'paid_by': paidBy,
      'shopping_list_item_id': shoppingListItemId,
      'currency_code': currencyCode,
      'converted_amount': convertedAmount,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'home_id': homeId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'category_id': categoryId,
      'paid_by': paidBy,
      'shopping_list_item_id': shoppingListItemId,
      'currency_code': currencyCode,
      'converted_amount': convertedAmount,
      'status': status,
      'created_by': createdBy,
    };
  }

  ExpenseModel copyWithModel({
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
    return ExpenseModel(
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
