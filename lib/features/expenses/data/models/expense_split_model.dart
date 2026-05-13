import '../../domain/entities/expense_split.dart';

class ExpenseSplitModel extends ExpenseSplit {
  const ExpenseSplitModel({
    required super.id,
    required super.expenseId,
    required super.memberId,
    required super.amount,
    super.createdAt,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      memberId: json['member_id'] as String,
      amount: json['amount'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_id': memberId,
      'amount': amount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'expense_id': expenseId,
      'member_id': memberId,
      'amount': amount,
    };
  }

  ExpenseSplitModel copyWithModel({
    String? id,
    String? expenseId,
    String? memberId,
    int? amount,
    DateTime? createdAt,
  }) {
    return ExpenseSplitModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
