import '../../../expenses/domain/repositories/settlement_repository.dart';
import '../../data/repositories/home_repository.dart';

class RemoveMemberWithBalanceCheck {
  final HomeRepository _homeRepository;
  final SettlementRepository _settlementRepository;

  RemoveMemberWithBalanceCheck(
    this._homeRepository,
    this._settlementRepository,
  );

  Future<RemoveMemberResult> call(RemoveMemberParams params) async {
    final hasUnsettled = await _settlementRepository.hasUnsettledBalances(
      homeId: params.homeId,
      userId: params.userId,
    );

    if (hasUnsettled && !params.force) {
      return RemoveMemberResult.hasUnsettledBalances();
    }

    await _homeRepository.removeMember(
      homeId: params.homeId,
      userId: params.userId,
    );

    return RemoveMemberResult.success();
  }
}

class RemoveMemberParams {
  final String homeId;
  final String userId;
  final bool force;

  const RemoveMemberParams({
    required this.homeId,
    required this.userId,
    this.force = false,
  });
}

class RemoveMemberResult {
  final bool success;
  final bool hasUnsettledBalances;

  const RemoveMemberResult._({
    required this.success,
    required this.hasUnsettledBalances,
  });

  factory RemoveMemberResult.success() =>
      const RemoveMemberResult._(success: true, hasUnsettledBalances: false);

  factory RemoveMemberResult.hasUnsettledBalances() =>
      const RemoveMemberResult._(success: false, hasUnsettledBalances: true);
}
