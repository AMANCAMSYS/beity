import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/settlement_remote_datasource.dart';
import '../../data/repositories/settlement_repository_impl.dart';
import '../../domain/entities/balance.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/repositories/settlement_repository.dart';

final settlementRemoteDataSourceProvider =
    Provider<SettlementRemoteDataSource>((ref) {
  final client = Supabase.instance.client;
  return SettlementRemoteDataSource(client);
});

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  final dataSource = ref.watch(settlementRemoteDataSourceProvider);
  return SettlementRepositoryImpl(dataSource);
});

final settlementsProvider =
    StreamProvider.autoDispose.family<List<Settlement>, String>((ref, homeId) {
  final repository = ref.watch(settlementRepositoryProvider);
  return repository.watchSettlements(homeId: homeId);
});

final balancesProvider =
    FutureProvider.family<List<Balance>, String>((ref, homeId) async {
  if (homeId.isEmpty) {
    throw Exception('لم يتم تحديد المنزل بشكل صحيح');
  }
  final repository = ref.watch(settlementRepositoryProvider);
  return repository.calculateBalances(homeId: homeId);
});

final hasUnsettledBalancesProvider =
    FutureProvider.family<bool, ({String homeId, String userId})>(
        (ref, params) async {
  final repository = ref.watch(settlementRepositoryProvider);
  return repository.hasUnsettledBalances(
    homeId: params.homeId,
    userId: params.userId,
  );
});
