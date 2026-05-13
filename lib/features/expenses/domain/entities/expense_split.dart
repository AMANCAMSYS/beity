class ExpenseSplit {
  final String id;
  final String expenseId;
  final String memberId;
  final int amount; // cents
  final DateTime? createdAt;

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amount,
    this.createdAt,
  });

  ExpenseSplit copyWith({
    String? id,
    String? expenseId,
    String? memberId,
    int? amount,
    DateTime? createdAt,
  }) {
    return ExpenseSplit(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
