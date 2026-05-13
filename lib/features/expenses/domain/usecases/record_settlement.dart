import '../entities/settlement.dart';
import '../repositories/settlement_repository.dart';

class RecordSettlement {
  final SettlementRepository _repository;

  RecordSettlement(this._repository);

  Future<Settlement> call(RecordSettlementParams params) async {
    return _repository.createSettlement(
      homeId: params.homeId,
      fromMember: params.fromMember,
      toMember: params.toMember,
      amount: params.amount,
      paymentMethod: params.paymentMethod,
      date: params.date,
    );
  }
}

class RecordSettlementParams {
  final String homeId;
  final String fromMember;
  final String toMember;
  final int amount;
  final String paymentMethod;
  final DateTime date;

  const RecordSettlementParams({
    required this.homeId,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    this.paymentMethod = 'cash',
    required this.date,
  });
}
