import '../entities/balance.dart';
import '../repositories/settlement_repository.dart';

class CalculateBalances {
  final SettlementRepository _repository;

  CalculateBalances(this._repository);

  Future<List<Balance>> call(String homeId) async {
    return _repository.calculateBalances(homeId: homeId);
  }
}
