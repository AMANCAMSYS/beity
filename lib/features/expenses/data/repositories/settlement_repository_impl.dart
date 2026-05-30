import 'dart:convert';
import 'package:beity/core/services/shared_prefs_provider.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/entities/balance.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_remote_datasource.dart';
import '../models/settlement_model.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementRemoteDataSource _dataSource;

  SettlementRepositoryImpl(this._dataSource);

  @override
  Future<List<Settlement>> getSettlements({
    required String homeId,
  }) async {
    final cacheKey = 'cached_settlements_$homeId';
    try {
      final remoteData = await _dataSource.getSettlements(homeId: homeId);
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(remoteData.map((s) => s.toJson()).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}
      return remoteData;
    } catch (e) {
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list.map((json) => SettlementModel.fromJson(json)).toList();
        }
      } catch (_) {}
      rethrow;
    }
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
    final cacheKey = 'cached_balances_$homeId';
    try {
      final remoteData = await _dataSource.calculateBalances(homeId: homeId);
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(remoteData.map((b) => {
          'memberA': b.memberA,
          'memberB': b.memberB,
          'netAmount': b.netAmount,
        }).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}
      return remoteData;
    } catch (e) {
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list.map((item) {
            final map = item as Map<String, dynamic>;
            return Balance(
              memberA: map['memberA'] as String? ?? '',
              memberB: map['memberB'] as String? ?? '',
              netAmount: (map['netAmount'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<bool> hasUnsettledBalances({
    required String homeId,
    required String userId,
  }) async {
    final cacheKey = 'cached_has_unsettled_${homeId}_$userId';
    try {
      final remoteData = await _dataSource.hasUnsettledBalances(
        homeId: homeId,
        userId: userId,
      );
      try {
        final prefs = AppPreferences.instance;
        await prefs.setBool(cacheKey, remoteData);
      } catch (_) {}
      return remoteData;
    } catch (e) {
      try {
        final prefs = AppPreferences.instance;
        if (prefs.containsKey(cacheKey)) {
          return prefs.getBool(cacheKey) ?? false;
        }
      } catch (_) {}
      return false;
    }
  }

  @override
  Stream<List<Settlement>> watchSettlements({
    required String homeId,
  }) async* {
    final cacheKey = 'cached_settlements_$homeId';

    // 1. Emit cached settlements immediately
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final List<dynamic> list = jsonDecode(cached);
        yield list.map((json) => SettlementModel.fromJson(json)).toList();
      }
    } catch (_) {}

    // 2. Subscribe to remote stream
    try {
      await for (final settlements in _dataSource.watchSettlements(homeId: homeId)) {
        try {
          final prefs = AppPreferences.instance;
          final rawJson = jsonEncode(settlements.map((s) => s.toJson()).toList());
          await prefs.setString(cacheKey, rawJson);
        } catch (_) {}
        yield settlements;
      }
    } catch (_) {
      // Absorb stream errors when offline
    }
  }
}
