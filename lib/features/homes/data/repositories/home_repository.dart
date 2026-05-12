import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_model.dart';
import '../models/home_member_model.dart';

abstract class HomeRepository {
  Future<HomeModel> createHome({
    required String name,
    required String type,
    String? defaultCurrency,
  });

  Future<List<HomeModel>> getUserHomes();

  Future<List<HomeMemberModel>> getHomeMembers(String homeId);

  Future<bool> hasHomes();

  Future<void> deleteHome(String homeId);
}

class HomeRepositoryImpl implements HomeRepository {
  final SupabaseClient _client;

  HomeRepositoryImpl(this._client);

  @override
  Future<HomeModel> createHome({
    required String name,
    required String type,
    String? defaultCurrency,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final response = await _client
          .from('homes')
          .insert({
            'name': name,
            'type': type,
            'owner_id': user.id,
            'default_currency': defaultCurrency ?? 'TRY',
          })
          .select()
          .single();

      return HomeModel.fromJson(response);
    } catch (e) {
      throw Exception('فشل إنشاء المنزل: ${e.toString()}');
    }
  }

  @override
  Future<List<HomeModel>> getUserHomes() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final response = await _client
          .from('home_members')
          .select('homes(*), homes!inner(*)')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .isFilter('deleted_at', null);

      final homes = <HomeModel>[];
      for (final item in response) {
        if (item['homes'] != null) {
          homes.add(HomeModel.fromJson(item['homes'] as Map<String, dynamic>));
        }
      }

      return homes;
    } catch (e) {
      throw Exception('فشل جلب المنازل: ${e.toString()}');
    }
  }

  @override
  Future<List<HomeMemberModel>> getHomeMembers(String homeId) async {
    try {
      final response = await _client
          .from('home_members')
          .select('*, users!inner(full_name, email)')
          .eq('home_id', homeId)
          .eq('status', 'active')
          .isFilter('deleted_at', null);

      return response.map((item) {
        final userData = item['users'] as Map<String, dynamic>?;
        return HomeMemberModel.fromJson({
          ...item,
          'user_name': userData?['full_name'],
          'user_email': userData?['email'],
        });
      }).toList();
    } catch (e) {
      throw Exception('فشل جلب الأعضاء: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasHomes() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('home_members')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .isFilter('deleted_at', null)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> deleteHome(String homeId) async {
    try {
      await _client
          .from('homes')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', homeId);
    } catch (e) {
      throw Exception('فشل حذف المنزل: ${e.toString()}');
    }
  }
}
