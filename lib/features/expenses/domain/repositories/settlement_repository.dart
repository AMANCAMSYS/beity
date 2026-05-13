import '../entities/settlement.dart';
import '../entities/balance.dart';

abstract class SettlementRepository {
  Future<List<Settlement>> getSettlements({
    required String homeId,
  });

  Future<Settlement> createSettlement({
    required String homeId,
    required String fromMember,
    required String toMember,
    required int amount,
    String paymentMethod = 'cash',
    required DateTime date,
  });

  Future<List<Balance>> calculateBalances({
    required String homeId,
  });

  Future<bool> hasUnsettledBalances({
    required String homeId,
    required String userId,
  });

  Stream<List<Settlement>> watchSettlements({
    required String homeId,
  });
}
