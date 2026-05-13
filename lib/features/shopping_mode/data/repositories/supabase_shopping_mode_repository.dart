import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_mode_session_model.dart';
import 'shopping_mode_repository.dart';

class SupabaseShoppingModeRepository implements ShoppingModeRepository {
  final SupabaseClient _client;

  SupabaseShoppingModeRepository(this._client);

  @override
  Future<ShoppingModeSessionModel?> getActiveSession({
    required String userId,
    required String listId,
  }) async {
    final response = await _client
        .from('shopping_mode_sessions')
        .select()
        .eq('user_id', userId)
        .eq('shopping_list_id', listId)
        .filter('ended_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return ShoppingModeSessionModel.fromJson(response);
  }

  @override
  Future<ShoppingModeSessionModel> startSession({
    required String listId,
    required String userId,
    required String homeId,
    required int itemsTotalCount,
  }) async {
    final response = await _client
        .from('shopping_mode_sessions')
        .insert({
          'shopping_list_id': listId,
          'user_id': userId,
          'home_id': homeId,
          'items_total_count': itemsTotalCount,
        })
        .select()
        .single();

    return ShoppingModeSessionModel.fromJson(response);
  }

  @override
  Future<ShoppingModeSessionModel> endSession({
    required String sessionId,
    required int itemsPurchasedCount,
  }) async {
    final response = await _client
        .from('shopping_mode_sessions')
        .update({
          'ended_at': DateTime.now().toIso8601String(),
          'items_purchased_count': itemsPurchasedCount,
        })
        .eq('id', sessionId)
        .select()
        .single();

    return ShoppingModeSessionModel.fromJson(response);
  }

  @override
  Future<void> updateSessionCounts({
    required String sessionId,
    required int itemsPurchasedCount,
  }) async {
    await _client
        .from('shopping_mode_sessions')
        .update({
          'items_purchased_count': itemsPurchasedCount,
        })
        .eq('id', sessionId);
  }

  @override
  Future<List<ShoppingModeSessionModel>> getShoppingHistory({
    required String userId,
    int limit = 20,
  }) async {
    final response = await _client
        .from('shopping_mode_sessions')
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ShoppingModeSessionModel.fromJson(json))
        .toList();
  }
}
