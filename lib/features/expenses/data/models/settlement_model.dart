import '../../domain/entities/settlement.dart';

class SettlementModel extends Settlement {
  const SettlementModel({
    required super.id,
    required super.homeId,
    required super.fromMember,
    required super.toMember,
    required super.amount,
    super.paymentMethod = 'cash',
    required super.date,
    required super.createdBy,
    super.createdAt,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      fromMember: json['from_member'] as String,
      toMember: json['to_member'] as String,
      amount: json['amount'] as int,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      date: DateTime.parse(json['date'] as String),
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'from_member': fromMember,
      'to_member': toMember,
      'amount': amount,
      'payment_method': paymentMethod,
      'date': date.toIso8601String().split('T')[0],
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'home_id': homeId,
      'from_member': fromMember,
      'to_member': toMember,
      'amount': amount,
      'payment_method': paymentMethod,
      'date': date.toIso8601String().split('T')[0],
      'created_by': createdBy,
    };
  }

  SettlementModel copyWithModel({
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
    return SettlementModel(
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
