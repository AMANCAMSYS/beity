class Settlement {
  final String id;
  final String homeId;
  final String fromMember;
  final String toMember;
  final int amount; // cents
  final String paymentMethod; // 'cash', 'transfer', 'other'
  final DateTime date;
  final String createdBy;
  final DateTime? createdAt;

  const Settlement({
    required this.id,
    required this.homeId,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    this.paymentMethod = 'cash',
    required this.date,
    required this.createdBy,
    this.createdAt,
  });

  Settlement copyWith({
    String? id,
    String? homeId,
    String? fromMember,
    String? toMember,
    int? amount,
    String? paymentMethod,
    DateTime? date,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Settlement(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      fromMember: fromMember ?? this.fromMember,
      toMember: toMember ?? this.toMember,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
