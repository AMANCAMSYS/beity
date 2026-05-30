import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settlement_model.dart';
import '../../domain/entities/balance.dart';

class SettlementRemoteDataSource {
  final SupabaseClient _client;

  SettlementRemoteDataSource(this._client);

  Future<List<SettlementModel>> getSettlements({
    required String homeId,
  }) async {
    final response = await _client
        .from('settlements')
        .select()
        .eq('home_id', homeId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => SettlementModel.fromJson(json))
        .toList();
  }

  Future<SettlementModel> createSettlement({
    required String homeId,
    required String fromMember,
    required String toMember,
    required int amount,
    String paymentMethod = 'cash',
    required DateTime date,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final response = await _client
        .from('settlements')
        .insert({
          'home_id': homeId,
          'from_member': fromMember,
          'to_member': toMember,
          'amount': amount,
          'payment_method': paymentMethod,
          'date': date.toIso8601String().split('T')[0],
          'created_by': user.id,
        })
        .select()
        .single();

    return SettlementModel.fromJson(response);
  }

  Future<List<Balance>> calculateBalances({
    required String homeId,
  }) async {
    final response =
        await _client.rpc('calculate_home_balances', params: {
      'p_home_id': homeId,
    });

    return (response as List<dynamic>)
        .map((json) {
          final map = json as Map<String, dynamic>;
          return Balance(
            memberA: map['member_a'] as String? ?? '',
            memberB: map['member_b'] as String? ?? '',
            netAmount: (map['net_amount'] as num?)?.toInt() ?? 0,
          );
        })
        .toList();
  }

  Future<bool> hasUnsettledBalances({
    required String homeId,
    required String userId,
  }) async {
    final response =
        await _client.rpc('has_unsettled_balances', params: {
      'p_home_id': homeId,
      'p_user_id': userId,
    });

    return response == true;
  }

  Stream<List<SettlementModel>> watchSettlements({
    required String homeId,
  }) {
    return _client
        .from('settlements')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('date', ascending: false)
        .map((response) => response
            .map((json) => SettlementModel.fromJson(json))
            .toList());
  }
}
