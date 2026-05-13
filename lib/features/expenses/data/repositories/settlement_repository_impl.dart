import '../../domain/entities/settlement.dart';
import '../../domain/entities/balance.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_remote_datasource.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementRemoteDataSource _dataSource;

  SettlementRepositoryImpl(this._dataSource);

  @override
  Future<List<Settlement>> getSettlements({
    required String homeId,
  }) async {
    return _dataSource.getSettlements(homeId: homeId);
  }

  @override
  Future<Settlement> createSettlement({
    required String homeId,
    required String fromMember,
    required String toMember,
    required int amount,
    String paymentMethod = 'cash',
    required DateTime date,
  }) async {
    return _dataSource.createSettlement(
      homeId: homeId,
      fromMember: fromMember,
      toMember: toMember,
      amount: amount,
      paymentMethod: paymentMethod,
      date: date,
    );
  }

  @override
  Future<List<Balance>> calculateBalances({
    required String homeId,
  }) async {
    return _dataSource.calculateBalances(homeId: homeId);
  }

  @override
  Future<bool> hasUnsettledBalances({
    required String homeId,
    required String userId,
  }) async {
    return _dataSource.hasUnsettledBalances(
      homeId: homeId,
      userId: userId,
    );
  }

  @override
  Stream<List<Settlement>> watchSettlements({
    required String homeId,
  }) {
    return _dataSource.watchSettlements(homeId: homeId);
  }
}
